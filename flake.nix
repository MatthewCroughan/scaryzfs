{
  description = "A flake to enable scary experimental ZFS versions in your NixOS Configuration 💀";
  outputs = { self }: {
    nixosModules.default = import ./module.nix;
  };
}
