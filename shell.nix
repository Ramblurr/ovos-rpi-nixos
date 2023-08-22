{
  system ? "x86_64-linux",
  pkgs ? import <nixpkgs> {inherit system;},
}: let
  packages = [
    pkgs.zsh
    pkgs.git
    pkgs.qemu
    pkgs.qemu_kvm
  ];
in
  pkgs.mkShell {
    buildInputs = packages;
    shellHook = ''
      export SHELL=${pkgs.zsh}
    '';
  }
