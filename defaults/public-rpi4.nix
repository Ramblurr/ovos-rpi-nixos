{
  config,
  lib,
  pkgs,
  ...
}: {
  # A base configuration that doesn't do much but
  # at leasts boots into NixOS with OVOS
  # DHCP is enabled and the default user / pass is ovos / ovos
  # (requires an rpi with ethernet, it will not connect to wifi)
  raspberry-pi.hardware.platform.type = "rpi4";
  ovos.password.enable = true;
  ovos.gui.enable = false;
}
