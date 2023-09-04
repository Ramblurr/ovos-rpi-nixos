{
  config,
  lib,
  pkgs,
  nixos-raspberrypi,
  ...
}: {
  raspberry-pi.hardware.hifiberry-dacplusadc.enable = true;
  raspberry-pi.hardware.platform.type = "rpi4";
}
