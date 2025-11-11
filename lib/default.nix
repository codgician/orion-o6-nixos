{ pkgs }:

pkgs.lib.extend (
  self: super: with super; {
    # Get packages with upgrade script
    packagesWithUpdateScript = filterAttrs (k: v: v ? passthru && v.passthru ? updateScript) (
      (import ../pkgs { inherit pkgs; }).packages
    );
  }
)