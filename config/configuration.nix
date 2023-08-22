{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./ovos
    ./user-config.nix
  ];
}
