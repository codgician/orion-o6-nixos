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
      mkPkgs = system: import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # Library functions
      lib = forAllSystems (system: (import ./default.nix { pkgs = mkPkgs system; }).lib);

      # Packages
      legacyPackages = forAllSystems (system: import ./default.nix { pkgs = mkPkgs system; });
      packages = forAllSystems (
        system: nixpkgs.lib.filterAttrs (_: v: nixpkgs.lib.isDerivation v) self.legacyPackages.${system}
      );

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

      linuxPackages_6_6 = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        (import ./pkgs { inherit pkgs; }).mkKernelModules {
          inherit (pkgs.linuxPackages_6_6) kernel kernelModuleMakeFlags;
        }
      );
      
      linuxPackages_6_12 = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        (import ./pkgs { inherit pkgs; }).mkKernelModules {
          inherit (pkgs.linuxPackages_6_12) kernel kernelModuleMakeFlags;
        }
      );

      # Text formatters
      formatter = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        pkgs.writeShellApplication {
          name = "formatter";
          runtimeInputs = with pkgs; [
            treefmt
            nixfmt-rfc-style
            mdformat
            yamlfmt
          ];
          text = lib.getExe pkgs.treefmt;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ jq ];
          };
        }
      );
    };
}
