{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./containers.nix
    ./modules/roc.nix
    ./audio/pipewire.nix
  ];
  options = {
    ovos.password.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to set a password for the ovos user";
    };
    ovos.password.password = lib.mkOption {
      type = lib.types.str;
      # default = "ovos";
      default = "$6$qbm.15xyrMPZJOpE$KWqllLmWZL6sfNOnoX1rSVv5.cCvrf.eWXWueY1DxnS0yya0h9rmbNmLsJKG.vFrhn5SajLulzlWys8Tl.wmi1";
      description = "The password to set for the ovos user.";
    };
    ovos.wireless.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable wireless networking";
    };
    ovos.wireless.ssid = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The SSID to connect to";
    };
    ovos.wireless.password = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The password to use for the wireless network";
    };
    ovos.gui.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to install the ovos-gui";
    };
    ovos.sshKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The SSH key to use for the system";
    };
    ovos.container = {
      imageTag = lib.mkOption {
        type = lib.types.str;
        default = "alpha";
        description = "The tag to use for the ovos-docker containers";
      };
      imageRepo = lib.mkOption {
        type = lib.types.str;
        default = "docker.io/smartgic";
        description = "The docker image repository prefix to use for the ovos-docker containers";
      };
    };
    ovos.roc = {
      recv = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable the ROC receiver";
        };
        listenIp = lib.mkOption {
          type = lib.types.str;
          default = "0.0.0.0";
        };
        sourcePort = lib.mkOption {
          type = lib.types.int;
          default = 10001;
          description = "The source endpoint to use for the ROC receiver. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_recv.html";
        };
        repairPort = lib.mkOption {
          type = lib.types.int;
          default = 10002;
          description = "The repair endpoint to use for the ROC receiver. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_recv.html";
        };
        latencyMsec = lib.mkOption {
          type = lib.types.int;
          default = 0;
        };
      };
    };
  };
  config = {
    system.stateVersion = "23.11";

    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;

    boot.initrd.availableKernelModules = [
      "usbhid"
      "usb_storage"
      #"vc4"
      #"pcie_brcmstb" # required for the pcie bus to work
      #"reset-raspberrypi" # required for vl805 firmware to load
    ];

    boot.tmp.useTmpfs = true;
    boot.kernelParams = [
      # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
      # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
      # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
      #"cma=128M"
      "console=tty0"
    ];

    swapDevices = [
      {
        device = "/swapfile";
        size = 1024;
      }
    ];
    nix = {
      gc = lib.mkDefault {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    environment.systemPackages = with pkgs; [
      # dev packages, remove in the future
      jq
      python311
      nix-prefetch-docker

      # actual packages we need for ovos
      git
      alsa-utils
      docker-client # for docker compose, it'll talk to the podman socket
      podman-compose
      libraspberrypi
      raspberrypi-eeprom

      # friendly sysadmin tools
      htop
      ncdu
      bash
      vim
      curl
      wget
      jless
    ];

    documentation = {
      enable = true;
      doc.enable = false;
      man.enable = true;
      dev.enable = false;
    };

    services.openssh = {
      enable = true;
      settings = lib.mkDefault {
        PermitRootLogin = "prohibit-password";
      };
    };

    security.sudo.wheelNeedsPassword = false;
    sound.enable = true;

    security.pam.loginLimits = [
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "4194304";
      }
      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "95";
      }
      {
        domain = "@audio";
        item = "nice";
        type = "-";
        value = "-19";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "soft";
        value = "99999";
      }
      {
        domain = "@audio";
        item = "nofile";
        type = "hard";
        value = "99999";
      }
    ];

    virtualisation.podman = {
      dockerSocket.enable = true;
      enable = true;
    };

    networking = {
      hostName = "ovos";
      firewall.enable = false;
      useDHCP = true;
      interfaces.wlan0 = lib.mkIf config.ovos.wireless.enable {
        useDHCP = true;
      };
      interfaces.eth0 = {
        useDHCP = true;
      };

      wireless.enable = config.ovos.wireless.enable;
      wireless.interfaces = lib.mkIf config.ovos.wireless.enable ["wlan0"];
      wireless.networks = lib.mkIf config.ovos.wireless.enable {
        "${config.ovos.wireless.ssid}".psk = config.ovos.wireless.password;
      };
    };

    users.defaultUserShell = pkgs.bash;
    users.mutableUsers = false;
    users.groups = {
      ovos = {
        gid = 1000;
        name = "ovos";
      };
      spi = {};
      gpio = {};
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="spidev", KERNEL=="spidev0.0", GROUP="spi", MODE="0660"
      SUBSYSTEM=="bcm2835-gpiomem", KERNEL=="gpiomem", GROUP="gpio",MODE="0660"
      SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio  /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
      SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add",RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 660 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value'"
    '';
    users.users = {
      ovos = {
        uid = 1000;
        home = "/home/ovos";
        name = "ovos";
        group = "ovos";
        isNormalUser = true;
        extraGroups = ["wheel" "audio" "podman" "spi" "gpio"];
        hashedPassword = lib.mkIf config.ovos.password.enable config.ovos.password.password;
        openssh.authorizedKeys.keys =
          if config.ovos.sshKey != ""
          then [config.ovos.sshKey]
          else [];
      };
    };
    users.extraUsers.root.openssh.authorizedKeys.keys =
      if config.ovos.sshKey != ""
      then [config.ovos.sshKey]
      else [];
    environment.sessionVariables = {
      DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
      DOCKER_BUILDKIT = "1";
    };
    # This allows the ovos user systemd services to run without anyone logging in
    system.activationScripts = {
      enableLingering = ''
        # remove all existing lingering users
        rm -r /var/lib/systemd/linger
        mkdir /var/lib/systemd/linger
        # enable for the subset of declared users
        touch /var/lib/systemd/linger/ovos
      '';
    };
  };
}
