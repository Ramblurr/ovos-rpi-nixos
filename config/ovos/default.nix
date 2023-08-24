{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./containers.nix
  ];
  options = {
    # ovos.platform is a mkOption that can be one of rpi4 or rpi3
    ovos.platform = lib.mkOption {
      type = lib.types.enum [ "rpi3" "rpi4" ];
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
    boot.loader.generic-extlinux-compatible.enable = true;
    #boot.loader.raspberryPi.enable = true;
    #boot.loader.raspberryPi.version = 4;

    boot.kernelPackages =
      if config.ovos.platform == "rpi3"
      then lib.mkForce pkgs.linuxPackages_rpi3
      else lib.mkForce pkgs.linuxPackages_rpi4;

    boot.initrd.availableKernelModules = ["usbhid" "usb_storage"];
    boot.tmp.useTmpfs = true;
    boot.kernelParams = [
      # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
      # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
      # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
      "cma=128M"
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
      pipewire
      wireplumber
      pulseaudio
      pulsemixer
      roc-toolkit
      openfec
      docker-client # for docker compose, it'll talk to the podman socket
      podman-compose

      # friendly sysadmin tools
      htop
      ncdu
      bash
      vim
      curl
      wget
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
    security.rtkit.enable = false;
    sound.enable = true;
    hardware.pulseaudio.enable = pkgs.lib.mkForce false;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true; # ?
      pulse.enable = true;
      jack.enable = false;
      wireplumber.enable = true;
      audio.enable = true;
    };
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

    systemd.user.services = {
      pipewire.wantedBy = ["default.target"];
      wireplumber.wantedBy = ["default.target"];
      pipewire-pulse = {
        path = [pkgs.pulseaudio];
        wantedBy = ["default.target"];
      };
    };
    environment.etc."pipewire/pipewire.conf.d/100-user.conf" = {
      text =
        builtins.toJSON
        {
          "context.modules" = [
            {
              name = "libpipewire-module-rt";
              args = {
                "nice.level" = 20;
                "rt.prio" = 88;
                "rtportal.enabled" = false;
                "rtkit.enabled" = false;
                "rlimits.enabled" = true;
              };
              flags = ["ifexists" "nofail"];
            }
            {name = "libpipewire-module-protocol-native";}
            {name = "libpipewire-module-profiler";}
            {name = "libpipewire-module-spa-device-factory";}
            {name = "libpipewire-module-spa-node-factory";}
            # Config to make pipewire discover stuff around it with zeroconf.
            {name = "libpipewire-module-link-factory";}
            {name = "libpipewire-module-session-manager";}
            {name = "libpipewire-module-zeroconf-discover";}
            {name = "libpipewire-module-raop-discover";}
            #{
            #  name = "libpipewire-module-roc-sink";
            #  args = {
            #    "fec.code" = "disable";
            #    "remote.ip" = "192.168.0.244";
            #    "remote.source.port" = 10001;
            #    "remote.repair.port" = 10002;
            #    "sink.name" = "ROC Sink";
            #    "sink.props" = {
            #      "node.name" = "roc-sink";
            #    };
            #  };
            #}
          ];
        };
    };

    virtualisation.podman = {
      dockerSocket.enable = true;
      enable = true;
    };

    hardware = {
      enableRedistributableFirmware = true;
      firmware = [pkgs.wireless-regdb];
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
    };
    users.users = {
      ovos = {
        uid = 1000;
        home = "/home/ovos";
        name = "ovos";
        group = "ovos";
        isNormalUser = true;
        extraGroups = ["wheel" "audio" "podman"];
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
