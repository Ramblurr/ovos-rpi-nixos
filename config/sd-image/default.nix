{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    #./ovos-prebaked.nix
  ];
  # We import sd-image-aarch64.nix so we can build a config.system.build.sdImage
  # But it imports some modules we don't want, so disable them
  disabledModules = [
    "profiles/base.nix"
    "profiles/all-hardware.nix"
  ];

  # Overrides to https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix
  system.nixos.variant_id = "ovos";

  sdImage.compressImage = false;
  sdImage.imageName = "${config.sdImage.imageBaseName}-${pkgs.stdenv.hostPlatform.system}.img";
  sdImage.imageBaseName = "ovos-nix-sd-image";

  environment.etc."nixos/configuration.nix" = {
    source = ../configuration.nix;
    mode = "0660";
    user = "ovos";
    group = "ovos";
  };
  environment.etc."nixos/user-config.nix" = {
    source = ../user-config.nix;
    mode = "0660";
    user = "ovos";
    group = "ovos";
  };
  environment.etc."nixos/ovos" = {
    source = pkgs.copyPathToStore ../ovos;
    mode = "0660";
    user = "ovos";
    group = "ovos";
  };
}
