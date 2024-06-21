{
  description = "Modular configs/envs/package setups";

  outputs = { self, nixpkgs, ... }@inputs: let
    lib = import ./lib inputs;
  in {
    inherit lib;

    overlays.default = import ./overlay.nix lib;

    tests = import ./tests inputs;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "unstable";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      # url = "github:GrizzlT/home-manager/release-23.11-patched";
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
