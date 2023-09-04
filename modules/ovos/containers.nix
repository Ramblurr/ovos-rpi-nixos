{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./modules/services.nix
    ./modules/gui.nix
    ./containers-base.nix
    ./containers-skills.nix
  ];
}
