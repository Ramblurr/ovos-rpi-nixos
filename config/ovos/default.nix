{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
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
    ovos.ovosGitUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/OpenVoiceOS/ovos-docker.git";
      description = "The URL to the ovos-docker repository";
    };
    ovos.ovosGitRef = lib.mkOption {
      type = lib.types.str;
      default = "origin/main";
      description = "The git ref to use for the ovos-docker repository";
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

    #boot.kernelPackages = pkgs.linuxKernel.kernels.linux_rpi4;

    # !!! Needed for the virtual console to work on the RPi 3, as the default of 16M doesn't seem to be enough.
    # If X.org behaves weirdly (I only saw the cursor) then try increasing this to 256M.
    # On a Raspberry Pi 4 with 4 GB, you should either disable this parameter or increase to at least 64M if you want the USB ports to work.
    boot.kernelParams = ["cma=256M"];

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
      bash
      vim
      curl
      wget
      jq
      git
      python311

      # actual packages we need for ovos
      alsa-utils
      pipewire
      wireplumber
      pulseaudio
      pulsemixer
      docker-client # for docker compose, it'll talk to the podman socket
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
      interfaces.wlan0 = {
        useDHCP = true;
      };
      interfaces.eth0 = {
        useDHCP = true;
      };

      wireless.enable = true;
      wireless.interfaces = ["wlan0"];
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
        extraGroups = ["wheel" "audio"];

        openssh.authorizedKeys.keys = [
          config.ovos.sshKey
        ];
      };
    };
    users.extraUsers.root.openssh.authorizedKeys.keys = [
      config.ovos.sshKey
    ];

    systemd.user.services.ovos-docker = {
      description = "OVOS Docker";
      wantedBy = ["default.target"];
      script = ''
        #!${pkgs.bash}/bin/bash
        set -ex
        REPO_URL="${config.ovos.ovosGitUrl}"
        REF="${config.ovos.ovosGitRef}"
        TARGET_DIR="/home/ovos/ovos-docker"
        GIT=${pkgs.git}/bin/git

        if [ ! -d "$TARGET_DIR" ]; then
          $GIT clone "$REPO_URL" "$TARGET_DIR"
          cd "$TARGET_DIR"
          $GIT reset --hard $REF
        else
          cd "$TARGET_DIR"
          $GIT fetch
          $GIT reset --hard $REF
        fi
        cat <<EOL > /home/ovos/ovos-docker/compose/.env
        GPIO_GID=997
        HIVEMIND_CONFIG_FOLDER=~/hivemind/config
        HIVEMIND_SHARE_FOLDER=~/hivemind/share
        OVOS_CONFIG_FOLDER=~/ovos/config
        OVOS_SHARE_FOLDER=~/ovos/share
        OVOS_USER=ovos
        RENDER_GID=106
        TMP_FOLDER=~/ovos/tmp
        TZ=${config.ovos.timezone}
        VERSION=alpha
        XDG_RUNTIME_DIR=/run/user/1000
        EOL
        cd /home/ovos/ovos-docker/compose
        ${pkgs.docker-client}/bin/docker compose --project-name ovos --parallel 1 pull
        ${pkgs.docker-client}/bin/docker compose \
          --project-name ovos \
          --env-file .env \
          -f docker-compose.yml \
          -f docker-compose.skills.yml \
          -f docker-compose.raspberrypi.yml \
          up --detach --remove-orphans
      '';
      serviceConfig = {
        WorkingDirectory = "/home/ovos";
        KillMode = "process";
        Type = "oneshot";
        RemainAfterExit = "yes";
      };
      enable = true;
    };
    environment.sessionVariables = {
      DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
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
