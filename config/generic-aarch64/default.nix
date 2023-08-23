{...}: {
  imports = [
    #<nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix>
    <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];
  # Workaround: https://github.com/NixOS/nixpkgs/issues/154163
  # modprobe: FATAL: Module sun4i-drm not found in directory
  nixpkgs.overlays = [
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // {allowMissing = true;});
    })
  ];
}
