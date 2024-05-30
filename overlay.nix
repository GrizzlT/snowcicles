selfLib:
final: prev: {
  lib = final.lib // selfLib;
  mkProfile = final.callPackage ./lib/mk-profile.nix;
}
