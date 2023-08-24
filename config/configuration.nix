{
  config,
  lib,
  pkgs,
  ...
}: {
  # This file is an entrypoint and will be on the system at /etc/nixos/configuration.nix
  imports = [
    ./ovos
    ./user-config.nix
  ];
}
