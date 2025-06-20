# scaryzfs 💀

> [!CAUTION]
>
> There is a reason that ZFS isn't easily overridable in Nixpkgs without a large
> amounts of assertions and checks, and that ZFS developers do not distribute or
> make easily available random versions of ZFS.
>
> Using the wrong version, commit, experimental or untested versions of ZFS via
> scaryzfs may cause damage to your filesystem. Use at your own risk.

`scaryzfs` is a Nix flake that allows you to take manual control of the ZFS
sources being used in your nixos configuration, and use a fork or pull request
from ZFS upstream, despite the danger in doing so, in order to test or use more
recent Linux kernel versions with ZFS on NixOS.

## Usage

To enable `scaryzfs`, add it to your NixOS configuration flake like
this:

```nix
{
  inputs.scaryzfs.url = "github:matthewcroughan/scaryzfs";

  outputs = { self, nixpkgs, scaryzfs }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      modules =
        [ scaryzfs.nixosModules.default
          # ... other configuration ...
        ];
    };
  };
}
```

The nixos configuration `my-machine` in the example above will then be able to use the module like so

```nix
{
  scaryzfs = {
    enable = true;
    iKnowTheRisks = true;
    kernelPackages = pkgs.linuxPackages_testing;
    zfsSrc = pkgs.fetchFromGitHub {
      owner = "openzfs";
      repo = "zfs";
      rev = "395ed7126a6ee510306a3a9a220daf54c5a018d6";
      hash = "sha256-9MM4CM/G1r6w+oI0gUIDDiAn2lf5wxzX75FcUMs8d+c=";
    };
  };
}
```

## Fetching ZFS with Flake Inputs

You may wish to use flake inputs instead of manually fetching and hashing the sources like above, an example is shown below

```nix
{
  inputs.scaryzfs.url = "github:matthewcroughan/scaryzfs";
  inputs.zfs-src = {
    url = "github:openzfs/zfs/zfs-2.3.3-staging";
    flake = false;
  };

  outputs = { self, nixpkgs, scaryzfs, zfs-src }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      modules =
        [
          scaryzfs.nixosModules.default
          {
            scaryzfs = {
              enable = true;
              iKnowTheRisks = true;
              kernelPackages = pkgs.linuxPackages_testing;
              zfsSrc = zfs-src;
            };
          }
        ];
    };
  };
}
```

## Thanks

Thanks to [emilazy](https://github.com/emilazy) for putting up with a bunch of
questions about how ZFS is built in Nixpkgs

## Future Ideas
- Make a `package` option to allow building ZFS instead of just passing in
  the src, in case zfs upstream advances too much and requires more buildInputs
- Run the VM Tests from Nixpkgs in CI with these experimental versions, and add
  ZFS to our flake inputs in order to have an integration tested rolling release
  that is at least a little bit better than YOLOing random revs with no testing
