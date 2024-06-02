{ self, nixpkgs, ... }:
let
  inherit (self) lib;

  mkNixOS = lib.mkNixOSes (all: name: settings: {
    modules = [{ services.resolved.extraConfig = "#${settings.moduleOpt or name}"; }];
    overlays = [ (_: _: { testOpt = settings.overlayOpt or "abc"; })];
    withExtra = config: {
      grizz.extraOpt = settings.extraOpt or (builtins.attrNames all);
    };
  });
in
nixpkgs.lib.runTests {
  testDefaultsOnly = let
    configurations = mkNixOS {
      host1 = {};
    };
    host1 = configurations.host1;
    cfg = configurations.host1.config;
  in {
    expr = [
      cfg.services.resolved.extraConfig
      host1.pkgs.testOpt
      (cfg.grizz ? "extraOpt")
      host1.grizz.extraOpt
    ];
    expected = [
      "#host1"
      "abc"
      false
      [ "host1" ]
    ];
  };

  testSupplySpecialized = let
    configurations = mkNixOS {
      host1 = {
        moduleOpt = "module-opt";
        overlayOpt = "overlay-opt";
        specialOnly = "special-only";
        hostPlatform = { system = "aarch64-linux"; };
        withExtra = config: {
          grizz.extraOpt = "custom";
        };
      };
    };
    host1 = configurations.host1;
    cfg = configurations.host1.config;
  in {
    expr = [
      cfg.services.resolved.extraConfig
      host1.pkgs.testOpt
      (cfg.grizz ? "extraOpt")
      host1.grizz.extraOpt
      cfg.grizz.settings.specialOnly
      host1.pkgs.system
    ];
    expected = [
      "#module-opt"
      "overlay-opt"
      false
      "custom"
      "special-only"
      "aarch64-linux"
    ];
  };

  testMultipleConfigs = let
    configurations = mkNixOS {
      host1 = {};
      host2 = {};
    };
  in {
    expr = [
      configurations.host1.grizz.extraOpt
      configurations.host2.grizz.extraOpt
    ];
    expected = [
      [ "host1" "host2" ]
      [ "host1" "host2" ]
    ];
  };
}
