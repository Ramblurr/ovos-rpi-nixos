{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    #<nixos-hardware/raspberry-pi/4>
    ./hifiberry.nix
    ./hardware/pkgs-overlays.nix
    ./hardware/cpu-revision.nix
  ];
  hardware = {
    enableRedistributableFirmware = true;
    firmware = [pkgs.wireless-regdb];
    i2c.enable = true;
    deviceTree = {
      enable = true;
      filter = "bcm2711-rpi-4-*.dtb";
      overlays = [
        {
          name = "spi";
          dtsText = ''
            /dts-v1/;
            /plugin/;

            / {
              compatible = "brcm,bcm2711";

              fragment@0 {
                target = <&spi0_cs_pins>;
                frag0: __overlay__ {
                  brcm,pins;
                };
              };

              fragment@1 {
                target = <&spi0>;
                __overlay__ {
                  cs-gpios;
                  status = "okay";
                };
              };

              fragment@2 {
                target = <&spidev1>;
                __overlay__ {
                  status = "disabled";
                };
              };

              fragment@3 {
                target = <&spi0_pins>;
                __dormant__ {
                  brcm,pins = <10 11>;
                };
              };

              __overrides__ {
                no_miso = <0>,"=3";
              };
            };
          '';
        }
        # In theory these should work, but they are all broken on 2023.05
        # references:
        # https://github.com/NixOS/nixos-hardware/issues/631
        # https://github.com/NixOS/nixpkgs/issues/125354
        # note: both the above issues are closed, but the problems still exist
        #{
        #  name = "hifiberry-dacplusadc";
        #  #  #dtboFile = "${pkgs.device-tree_rpi.overlays}/hifiberry-dacplusadc.dtbo";
        #  dtboFile = "${config.boot.kernelPackages.kernel}/dtbs/overlays/hifiberry-dacplusadc.dtbo";
        #}
        #"${config.boot.kernelPackages.kernel}/dtbs/overlays/hifiberry-dacplusadc.dtbo"
        #"${pkgs.device-tree_rpi.overlays}/hifiberry-dacplusadc.dtbo"
        #"${pkgs.device-tree_rpi.overlays}/hifiberry-amp.dtbo"
        #"${pkgs.device-tree_rpi.overlays}/hifiberry-dac.dtbo"
        #"${pkgs.device-tree_rpi.overlays}/hifiberry-digi.dtbo"
      ];
    };
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    raspberry-pi."4".hifiberry-dacplusadc.enable = true;
  };
}
