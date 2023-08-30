#!/usr/bin/env sh
set -ex

# Do you run nixos? Then use this script to build the image without docker
# You will need to add this line to your NixOS configuration to enable cross compilation
#   boot.binfmt.emulatedSystems = ["aarch64-linux"];

nix-build '<nixpkgs/nixos>' -A config.system.build.sdImage -I nixos-config=./config/sd-image-rpi4.nix \
  -I nixpkgs=flake:github:NixOS/nixpkgs/nixos-23.05 \
  --argstr system aarch64-linux \
  --option sandbox false
