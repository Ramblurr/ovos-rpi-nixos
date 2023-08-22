{
  config,
  lib,
  pkgs,
  ...
}: {
  # Disable ZFS. It is problematic on the raspberry pi and anyways we don't need it.
  nixpkgs.overlays = [
    (final: super: {
      zfs = super.zfs.overrideAttrs (_: {
        meta.platforms = [];
      });
    })
  ];
  system.stateVersion = "23.05";

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
    bash
    vim
    curl
    wget
    jq
    git

    python311
    alsa-utils
    pipewire
    wireplumber
    pulseaudio
    pulsemixer
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

  virtualisation.podman.enable = true;

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
      extraGroups = ["wheel" "docker" "audio"];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzseqIeUgemCgd3/vxkcmJtpVGFS1P3ajBDYaGHHwziIUO/ENkWrEfv/33DvaaY3QQYnSMePRrsHq5ESanwEdjbMBu1quQZZWhyh/M5rQdbfwFoh2BYjCq5hFhaNUl9cjZk3xjQGHVKlTBdFfpuvWtY9wGuh1rf/0hSQauMrxAZsgXVxRhCbY+/+Yjjwm904BrWxXULbrc5yyfpgwHOHhHbpl8NIQIN6OAn3/qcVb7DlGJpLUjfolkdBTY8zGAJxEWecJzjgwwccuWdrzcWliuw0j4fu/MDOonpVQBCY9WcZeKInGHYAKu+eZ/swxAP+9vAR4mc+l/SBYyzCWvM6zG8ebbDK1mkwq2t0G183/0KSxAPJ7OykFD1a/ifb+cXNYJjshCDN+M95A3s6aMEU4VER/9SmQp3YCZvQEDKOBHlqMqlbw0IYAYE/FfU2se+gLI74JizoHBv2OJcduYdV0Ba97fvrb1lYM+tg0VmKUCwCvI9+ZbT2bJH3sM6SE9xt8+3nx6sKzV6h6FlpvDC60Rr2mANsuW3lbqac05Wnmxzk0C8OoJPCqWEmzjyWLJvPq98cG4obJiNlnp7/7xmmhOwyqcy7gDQum1QDwrUJyBKBsJPelJOZJC0pKkerv4LdSZDTSxEVxomstK/WDzmkPK9uUWTEH69VU/bUMuejTNVQ== cardno:000500006944"
      ];
    };
  };
  users.extraUsers.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzseqIeUgemCgd3/vxkcmJtpVGFS1P3ajBDYaGHHwziIUO/ENkWrEfv/33DvaaY3QQYnSMePRrsHq5ESanwEdjbMBu1quQZZWhyh/M5rQdbfwFoh2BYjCq5hFhaNUl9cjZk3xjQGHVKlTBdFfpuvWtY9wGuh1rf/0hSQauMrxAZsgXVxRhCbY+/+Yjjwm904BrWxXULbrc5yyfpgwHOHhHbpl8NIQIN6OAn3/qcVb7DlGJpLUjfolkdBTY8zGAJxEWecJzjgwwccuWdrzcWliuw0j4fu/MDOonpVQBCY9WcZeKInGHYAKu+eZ/swxAP+9vAR4mc+l/SBYyzCWvM6zG8ebbDK1mkwq2t0G183/0KSxAPJ7OykFD1a/ifb+cXNYJjshCDN+M95A3s6aMEU4VER/9SmQp3YCZvQEDKOBHlqMqlbw0IYAYE/FfU2se+gLI74JizoHBv2OJcduYdV0Ba97fvrb1lYM+tg0VmKUCwCvI9+ZbT2bJH3sM6SE9xt8+3nx6sKzV6h6FlpvDC60Rr2mANsuW3lbqac05Wnmxzk0C8OoJPCqWEmzjyWLJvPq98cG4obJiNlnp7/7xmmhOwyqcy7gDQum1QDwrUJyBKBsJPelJOZJC0pKkerv4LdSZDTSxEVxomstK/WDzmkPK9uUWTEH69VU/bUMuejTNVQ== cardno:000500006944"
  ];
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
}
