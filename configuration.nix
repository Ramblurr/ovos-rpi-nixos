{ config, pkgs, lib, ... }:
{
  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;
 
  # !!! Set to specific linux kernel version
  boot.kernelPackages = pkgs.linuxKernel.kernels.linux_rpi4;

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

  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [ { device = "/swapfile"; size = 1024; } ];

  # systemPackages
  environment.systemPackages = with pkgs; [
    bash
    vim
    curl
    wget
    python311
    podman
    alsa-utils
    pipewire
    wireplumber
    pulseaudio
    pulsemixer
  ];

  services.openssh = {
      enable = true;
      permitRootLogin = "yes";
  };
  security.rtkit.enable = true;
  systemd.user.services.pipewire-pulse.path = [pkgs.pulseaudio];
  sound.enable = true;
  hardware.pulseaudio.enable = pkgs.lib.mkForce false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # ?
    pulse.enable = true;
    jack.enable = false;
    wireplumber.enable = true;
    lowLatency.enable = true;
    audio.enable = true;
  };

  virtualisation.podman.enable = true;
  networking.firewall.enable = false;

  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.wireless-regdb ];
  };

  networking = {
    useDHCP = true;
    interfaces.wlan0 = {
      useDHCP = true;
    };
    interfaces.eth0 = {
      useDHCP = true;
    };

    wireless.enable = true;
    wireless.interfaces = [ "wlan0" ];
  };

  users.defaultUserShell = pkgs.bash;
  users.mutableUsers = true;
  users.groups = {
    nixos = {
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
      shell = pkgs.bash;
      extraGroups = [ "wheel" ];
    };
  };
  users.extraUsers.root.openssh.authorizedKeys.keys = [
     "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzseqIeUgemCgd3/vxkcmJtpVGFS1P3ajBDYaGHHwziIUO/ENkWrEfv/33DvaaY3QQYnSMePRrsHq5ESanwEdjbMBu1quQZZWhyh/M5rQdbfwFoh2BYjCq5hFhaNUl9cjZk3xjQGHVKlTBdFfpuvWtY9wGuh1rf/0hSQauMrxAZsgXVxRhCbY+/+Yjjwm904BrWxXULbrc5yyfpgwHOHhHbpl8NIQIN6OAn3/qcVb7DlGJpLUjfolkdBTY8zGAJxEWecJzjgwwccuWdrzcWliuw0j4fu/MDOonpVQBCY9WcZeKInGHYAKu+eZ/swxAP+9vAR4mc+l/SBYyzCWvM6zG8ebbDK1mkwq2t0G183/0KSxAPJ7OykFD1a/ifb+cXNYJjshCDN+M95A3s6aMEU4VER/9SmQp3YCZvQEDKOBHlqMqlbw0IYAYE/FfU2se+gLI74JizoHBv2OJcduYdV0Ba97fvrb1lYM+tg0VmKUCwCvI9+ZbT2bJH3sM6SE9xt8+3nx6sKzV6h6FlpvDC60Rr2mANsuW3lbqac05Wnmxzk0C8OoJPCqWEmzjyWLJvPq98cG4obJiNlnp7/7xmmhOwyqcy7gDQum1QDwrUJyBKBsJPelJOZJC0pKkerv4LdSZDTSxEVxomstK/WDzmkPK9uUWTEH69VU/bUMuejTNVQ== cardno:000500006944"
  ];
}
