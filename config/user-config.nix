{
  config,
  lib,
  pkgs,
  ...
}: {
  # This is the default configuration for the image that is downloadable on
  # https://github.com/Ramblurr/ovos-rpi-nixos/releases
  # It is meant as an example for people to play with
  # You probably want to build your own image with your own configuration
  # See user-config-example.nix and refer to the README
  ovos.platform = "rpi4";
  ovos.timezone = "Europe/Berlin";
  ovos.password.enable = true; # default creds are ovos / ovos
}
