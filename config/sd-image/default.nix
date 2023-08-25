{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    #./ovos-prebaked.nix
  ];

  # Overrides to https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix
  system.nixos.variant_id = "ovos";

  sdImage.compressImage = false;
  sdImage.imageName = "${config.sdImage.imageBaseName}-${pkgs.stdenv.hostPlatform.system}.img";
  sdImage.imageBaseName = "ovos-nix-sd-image";

  environment.etc."nixos/configuration.nix" = {
    source = ../configuration.nix;
    mode = "file";
    user = "ovos";
  };
  environment.etc."nixos/user-config.nix" = {
    source = ../user-config.nix;
    mode = "file";
    user = "ovos";
  };
  environment.etc."nixos/ovos" = {
    source = pkgs.copyPathToStore ../ovos;
    mode = "file";
    user = "ovos";
  };
}
