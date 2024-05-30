{ ... }:
let
  mkProfiles = { profiles, basePathEnvDefault ? "GRIZZ_PROFILES" }: {
     profiles = pkgs: let
        mkProfile = pkgs.callPackage ./mk-profile.nix { inherit basePathEnvDefault; };
      in
        builtins.mapAttrs (_: v: pkgs.callPackage v { inherit mkProfile; }) profiles;
    defs = profiles;
    inherit basePathEnvDefault;
  };
in
  mkProfiles
