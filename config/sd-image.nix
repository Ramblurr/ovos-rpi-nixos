{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./rpi4
    ./ovos
    ./user-config.nix
  ];

  # Overrides to https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix
  system.nixos.variant_id = "ovos";

  sdImage.compressImage = false;
  sdImage.imageBaseName = "ovos-nix-sd-image";
}
