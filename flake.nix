{
  description = "A subset of out-of-tree packages for Radxa Orion O6 ported to NixOS";

  nixConfig = {
    allow-import-from-derivation = "true";
    extra-substituters = [ ];
    extra-trusted-public-keys = [ ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    flake-compat.url = "github:edolstra/flake-compat";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f system);
      mkPkgs = system: import nixpkgs { inherit system; };
    in
    {
      # Overlays
      overlay = self.overlays.default;
      overlays.default =
        final: prev:
        let
          inherit (import ./pkgs { pkgs = prev; }) mkKernelModules packages;
        in
        packages
        // {
          linuxKernel = prev.linuxKernel // {
            packagesFor =
              kernel:
              (prev.linuxKernel.packagesFor kernel).extend (
                lpself: lpsuper:
                mkKernelModules {
                  inherit (lpsuper) kernel kernelModuleMakeFlags;
                }
              );
          };
        };

      # Packages
      packages = forAllSystems (system: (import ./pkgs { pkgs = mkPkgs system; }).packages);

      # Text formatters
      formatter = forAllSystems (
        system:
        with (mkPkgs system);
        writeShellApplication {
          name = "formatter";
          runtimeInputs = [
            treefmt
            nixfmt-rfc-style
            mdformat
            yamlfmt
          ];
          text = lib.getExe treefmt;
        }
      );

      devShells = forAllSystems (
        system: with (mkPkgs system); {
          default = mkShell {
            buildInputs = [ jq ];
          };
        }
      );
    };
}
