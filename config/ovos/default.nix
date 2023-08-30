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
    #./audio/pulseaudio.nix
    ./audio/pipewire.nix
  ];
  options = {
    # ovos.platform is a mkOption that can be one of rpi4 or rpi3
    ovos.platform = lib.mkOption {
      type = lib.types.enum ["rpi3" "rpi4"];
      default = "rpi4";
      description = "The platform to build for";
    };
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
    ovos.timezone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Berlin";
      description = "The timezone to use for the system";
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
        source = lib.mkOption {
          type = lib.types.str;
          default = "rtp+rs8m://0.0.0.0:10001";
          description = "The source endpoint to use for the ROC receiver. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_recv.html";
        };
        repair = lib.mkOption {
          type = lib.types.str;
          default = "rs8m://0.0.0.0:10002";
          description = "The repair endpoint to use for the ROC receiver. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_recv.html";
        };
        control = lib.mkOption {
          type = lib.types.str;
          default = "rtcp://0.0.0.0:10003";
          description = "The control endpoint to use for the ROC receiver. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_recv.html";
        };

        extraArgs = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Extra arguments for roc-recv. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_recv.html";
        };
      };

      send = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to enable the ROC sender";
        };
        source = lib.mkOption {
          type = lib.types.str;
          default = "alsa://hw:1,0";
          description = "The source endpoint to use for the ROC sender. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_send.html";
        };
        repair = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = "The repair endpoint to use for the ROC sender. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_send.html";
        };
        control = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = "The control endpoint to use for the ROC sender. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_send.html";
        };

        extraArgs = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Extra arguments for roc-send. Refer to https://roc-streaming.org/toolkit/docs/manuals/roc_send.html";
        };
      };
    };
  };
  config = {
    # Disable ZFS. It is problematic on the raspberry pi and anyways we don't need it.
    nixpkgs.overlays = [
      (final: super: {
        zfs = super.zfs.overrideAttrs (_: {
          meta.platforms = [];
        });
      })
    ];
    system.stateVersion = "23.05";
    time.timeZone = config.ovos.timezone;

    boot.loader.grub.enable = false;
    # Enables the generation of /boot/extlinux/extlinux.conf
    boot.loader.generic-extlinux-compatible.enable = lib.mkForce true;
    boot.loader.raspberryPi = {
      enable = false;
      version = 4;
      firmwareConfig = ''
        dtoverlay=hifiberry-dacplusadc
        dtparam=audio=off
        force_eeprom_read=0
      '';
      #dtoverlay=vc4-kms-v3d,noaudio
    };

    boot.kernelPackages =
      if config.ovos.platform == "rpi3"
      then lib.mkForce pkgs.linuxPackages_rpi3
      else lib.mkForce pkgs.linuxPackages_rpi4;

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

    # File systems configuration for using the installer's partition layout
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/NIXOS_SD";
        fsType = "ext4";
      };
    };

    swapDevices = [
      {
        device = "/swapfile";
        size = 1024;
      }
    ];
    nix = {
      gc = {
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
      settings = {
        PermitRootLogin = lib.mkForce "prohibit-password";
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
