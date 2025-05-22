{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.scaryzfs;

  tracedKernelPackages = lib.warn
    ''
    [scaryzfs]: You have enabled scaryzfs with experimental ZFS sources.
    boot.kernelPackages is set to: ${cfg.kernelPackages.kernel.version}
    Make sure this kernel is compatible with the ZFS version you're building
    ''
    cfg.kernelPackages;
in {
  options.scaryzfs = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable scary experimental ZFS setup";
    };

    iKnowTheRisks = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Acknowledgement that you understand the risks of enabling experimental ZFS.

        WARNING: This configuration uses unreleased ZFS sources and patches the kernel package.
        It may cause data loss, instability, or make your system unbootable. Use only if you
        absolutely know what you're doing and are prepared for the consequences
      '';
    };

    kernelPackages = mkOption {
      default = null;
      defaultText = literalExpression "null";
      description = "The kernel packages to use for the scary experimental ZFS setup. This sets boot.kernelPackages on your behalf";
    };

    zfsSrc = mkOption {
      type = types.nullOr types.path;
      default = null;
      defaultText = literalExpression "null";
      description = ''
        The source for the ZFS codebase you want to use with scaryzfs

        You must provide this manually, e.g., using `pkgs.fetchFromGitHub`
      '';
    };
  };

  config = let
    nullKernelMsg = ''
      scaryzfs requires that you explicitly set `scaryzfs.kernelPackages` in your configuration.

      This has the effect of setting `boot.kernelPackages` for you.
      Usually you would set `scaryzfs.kernelPackages = pkgs.linuxPackages_testing` in order to use the latest kernel

      This is to ensure you understand and control the kernel being used with experimental ZFS
    '';
    makeZfsPackage = { callPackage, configFile, kernel ? null }: (
      (callPackage "${pkgs.path}/pkgs/os-specific/linux/zfs/generic.nix" {
        inherit configFile kernel;
      } {
        kernelModuleAttribute = "scaryzfs";
        kernelCompatible = kernel: kernel.kernelOlder "9999999999.9999999999";
        version = "scary";
        rev = "";
        hash = "";
        tests = {};
      }).overrideAttrs (old: {
        src = cfg.zfsSrc;
        configureFlags = old.configureFlags ++ [ "--enable-linux-experimental" ];
        meta.broken = false;
      })
    );
  in mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.iKnowTheRisks;
        message = ''
          scaryzfs.enable = true requires scaryzfs.iKnowTheRisks = true.

          This setup uses experimental ZFS sources and overrides kernelPackages.
          Proceeding without understanding the risks can lead to system instability or data loss
        '';
      }
      {
        assertion = cfg.zfsSrc != null;
        message = ''
          scaryzfs requires that you explicitly set `scaryzfs.zfsSrc` in your configuration.

          This must be a source expression resulting in a path such as `pkgs.fetchFromGitHub { ... }` or a flake input.
          Setting a default upstream source is too dangerous — you must acknowledge and manage it yourself.
        '';
      }
    ];

    boot.kernelPackages = if cfg.kernelPackages == null then builtins.throw nullKernelMsg else (tracedKernelPackages.extend (self: super: {
      scaryzfs = makeZfsPackage {
        callPackage = self.callPackage;
        configFile = "kernel";
        kernel = self.kernel;
      };
    }));

    boot.zfs.package = makeZfsPackage {
      callPackage = pkgs.callPackage;
      configFile = "user";
    };
  };
}
