# Compatibility layer for tools that expect a default.nix
# This allows nix-update and similar tools to work with our flake-based repository
{
  system ? builtins.currentSystem,
  overlays ? [ ],
}:

let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgs = fetchTarball {
    url = "https://github.com/nixos/nixpkgs/archive/${lock.nodes.nixpkgs.locked.rev}.tar.gz";
    sha256 = lock.nodes.nixpkgs.locked.narHash;
  };

  pkgs = import nixpkgs {
    inherit system overlays;
  };
in
# Return the packages attrset directly so that tools can access them
# e.g., (import ./. {}).edk2-cix
(import ./pkgs { inherit pkgs; }).packages
