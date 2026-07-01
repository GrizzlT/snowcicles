selfLib:
final: prev: let
    toolchain = final.rust-bin.stable."1.96.0".minimal;
    rustPlatform = prev.makeRustPlatform {
      cargo = toolchain;
      rustc = toolchain;
    };
in {
  lib = final.lib // {
    grizz = selfLib;

    rayfish = final.callPackage ./pkgs/rayfish.nix { inherit rustPlatform; };
  };
}
