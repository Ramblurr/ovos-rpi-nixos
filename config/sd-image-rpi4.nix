{
  config,
  pkgs,
  lib,
  ...
}: {
  # This is an entrypoint for building an sd card image for the rpi4
  imports = [
    ./sd-image
    ./user-config.nix
    ./ovos
    ./sd-image/rpi4
  ];
  ovos.platform = lib.mkDefault "rpi4";
}
