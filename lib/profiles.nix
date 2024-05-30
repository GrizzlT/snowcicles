{ ... }:
let
  mkProfiles = { defs, basePathEnvDefault ? "GRIZZ_PROFILES" }: {
     profiles = pkgs: let
        mkProfile = pkgs.callPackage ./mk-profile.nix { inherit basePathEnvDefault; };
      in
        builtins.mapAttrs (_: v: pkgs.callPackage v { inherit mkProfile; }) defs;
    inherit defs basePathEnvDefault;
  };
in
  mkProfiles
