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
}
