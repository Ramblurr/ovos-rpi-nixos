# source: https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/4/cpu-revision.nix
# License: Creative Commons Zero v1.0 Universal
{
  hardware.deviceTree.overlays = [
    {
      name = "rpi4-cpu-revision";
      dtsText = ''
        /dts-v1/;
        /plugin/;

        / {
          compatible = "raspberrypi,4-model-b";

          fragment@0 {
            target-path = "/";
            __overlay__ {
              system {
                linux,revision = <0x00d03114>;
              };
            };
          };
        };
      '';
    }
  ];
}
