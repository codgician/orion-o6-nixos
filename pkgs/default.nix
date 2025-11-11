{ pkgs }:
let
  inherit (pkgs) lib;

  # Build packages from a directory, allowing cross-package references
  mkPackageSet =
    extraArgs: path:
    lib.fix (
      self:
      let
        dirs = lib.filterAttrs (_: type: type == "directory") (builtins.readDir path);
        callPackage = lib.callPackageWith (pkgs // extraArgs // self);
        baseArgs = extraArgs;
      in
      lib.mapAttrs (name: _: callPackage (path + "/${name}") baseArgs) dirs
    );

  # Regular non-kernel module packages
  regularPackages = mkPackageSet { } ./regular;

  # Function for building kernel modules with kernel-specific arguments
  mkKernelModules =
    { kernel, kernelModuleMakeFlags }:
    mkPackageSet (
      regularPackages
      // {
        inherit kernel kernelModuleMakeFlags;
      }
    ) ./kernel-modules;
in
{
  inherit mkKernelModules;
  packages = regularPackages;
}
