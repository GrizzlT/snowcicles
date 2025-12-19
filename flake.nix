{
  description = "Modular configs/envs/package setups";

  outputs = { self, nixpkgs, ... }@inputs: let
    lib = import ./lib inputs;

    mkNixOS = lib.mkNixOSes (all: name: settings: {
      withExtra = config: {
        grizz.testCheck = "${name}qsmdlfkj-${toString settings.myOpt}";
      };
    });

    mkHm = lib.mkHmManagers {
      defaults = all: name: settings: {
        withExtra = config: {
          grizz.testCheck = "${name}mliqsjef-${settings.hostname}";
        };
      };
      hosts = {
        clevo = "x86_64-linux";
        raspi = "aarch64-linux";
      };
    };
  in {
    inherit lib;

    overlays.default = import ./overlay.nix lib;

    tests = import ./tests inputs;

    nixosConfigurations = mkNixOS {
      test.myOpt = "Testing stuff";
    };

    homeConfigurations = mkHm {
      test = {
        modules = [{
          home = {
            username = "grizz";
            homeDirectory = "/home/grizz";
            stateVersion = "23.11";
          };
        }];
      };
    };
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
