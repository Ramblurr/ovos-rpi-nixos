{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-raspberrypi.url = "github:ramblurr/nixos-raspberrypi";
  };
  outputs = {
    self,
    nixpkgs,
    nixos-raspberrypi,
  }: {
    nixosModules = {
      ovos = import ./modules/ovos;
    };
    images = {
      ovos-rpi4-public =
        (self.nixosConfigurations.ovos-rpi4.extendModules {
          modules = [
            nixos-raspberrypi.nixosModules.sd-image-rpi4
            ./defaults/public-rpi4.nix
            {
              system.nixos.variant_id = "ovos";
              sdImage.imageBaseName = "ovos-rpi4-nix-sd-image";
            }
          ];
        })
        .config
        .system
        .build
        .sdImage;
    };
    nixosConfigurations = {
      ovos-rpi4 = nixos-raspberrypi.nixosConfigurations.rpi4.extendModules {
        modules = [
          ./modules/ovos
        ];
      };
      ovos-rpi3 = nixos-raspberrypi.nixosConfigurations.rpi3.extendModules {
        modules = [
          ./modules/ovos
        ];
      };
    };
  };
}
