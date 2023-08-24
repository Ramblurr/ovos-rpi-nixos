{
  config,
  pkgs,
  lib,
  ...
}: {
  # This is an entrypoint for building an sd card image for the rpi3
  imports = [
    ./sd-image
    ./user-config.nix
    ./ovos
    ./sd-image/rpi3
  ];
  ovos.platform = lib.mkDefault "rpi3";
}
