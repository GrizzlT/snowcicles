{ self, nixpkgs, ... }:
let
  inherit (self) lib;

  mkHm = lib.mkHmManagers {
    defaults = all: name: settings: {
      modules = [{
        home = {
          username = "${settings.moduleOpt or name}";
          homeDirectory = "/home/default";
          stateVersion = "24.05";
        };
      }];
      overlays = [ (_: _: { testOpt = settings.overlayOpt or "abc"; })];
      withExtra = config: {
        grizz.extraOpt = settings.extraOpt or (builtins.attrNames all);
      };
    };
    hosts = {
      defaultHost = "x86_64-linux";
    };
  };
in
nixpkgs.lib.runTests {
  testDefaultsOnly = let
    configurations = mkHm {
      home1 = {};
    };
    home1 = configurations."home1@defaultHost";
    cfg = home1.config;
  in {
    expr = [
      cfg.home.username
      home1.pkgs.testOpt
      (cfg.grizz ? "extraOpt")
      home1.grizz.extraOpt
      home1.grizz.settings.hostname
    ];
    expected = [
      "home1"
      "abc"
      false
      [ "home1" ]
      "defaultHost"
    ];
  };

  testSupplySpecialized = let
    configurations = mkHm {
      home1 = {
        moduleOpt = "module-opt";
        overlayOpt = "overlay-opt";
        specialOnly = "special-only";
        withExtra = config: {
          grizz.extraOpt = "custom";
        };
        hosts.special = "aarch64-linux";
      };
    };
    home1 = configurations."home1@special";
    cfg = home1.config;
  in {
    expr = [
      cfg.home.username
      home1.pkgs.testOpt
      (cfg.grizz ? "extraOpt")
      home1.grizz.extraOpt
      cfg.grizz.settings.specialOnly
      home1.pkgs.system
    ];
    expected = [
      "module-opt"
      "overlay-opt"
      false
      "custom"
      "special-only"
      "aarch64-linux"
    ];
  };

  testMultipleConfigs = let
    configurations = mkHm {
      home1 = {};
      home2 = {};
    };
  in {
    expr = [
      configurations."home1@defaultHost".grizz.extraOpt
      configurations."home2@defaultHost".grizz.extraOpt
    ];
    expected = [
      [ "home1" "home2" ]
      [ "home1" "home2" ]
    ];
  };
}
