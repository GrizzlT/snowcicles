{
  description = "Modular configs/envs/package setups";

  outputs = { self, nixpkgs, ... }@inputs: let
    lib = import ./lib inputs;

    mkNixOS = lib.mkNixOSes {};
  in {
    inherit lib;

    nixosConfigurations = mkNixOS {
      test = {};
    };
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
}
