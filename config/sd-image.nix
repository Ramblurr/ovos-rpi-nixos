{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    #<nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel.nix>
    #<nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    ./rpi4
    ./ovos
  ];

  # Overrides to https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix
  system.nixos.variant_id = "ovos";
  sdImage.compressImage = false;
}
