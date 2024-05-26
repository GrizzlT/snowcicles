{ self, nixpkgs, ... }@inputs:
let
  lib = nixpkgs.lib;

  mkNixOS = name: settings: let
    # include flake lib + unstable nixpkgs
    defaultOverlay = pkgs: self0: super: {
      lib = super.lib // {
        grizz = self.lib.nixos;
      };
      unstable = import inputs.unstable ({
        inherit (pkgs) config;
      } // (if (buildPlatform != null && buildPlatform != hostPlatform) then {
        localSystem = buildPlatform;
        crossSystem = hostPlatform;
      } else {
        localSystem = hostPlatform;
      }));
    };

    # all modules to include by default
    modules = [

    ] ++ (settings.modules or []);

    # overlays to be applied to nixpkgs
    overlays = [

    ] ++ (settings.overlays or []);

    # cross compilation support
    hostPlatform = settings.system or (settings.hostPlatform or { system = "x86_64-linux"; });
    buildPlatform = if (settings ? hostPlatform) then settings.buildPlatform or "x86_64-linux" else settings.buildPlatform or null;

    # extra attrs
    extraAttrHook = settings.withExtra or (_: {});

    # Enable configuration extendModules
    # add grizz metadata
    withExtraAttrs = finalSet: (finalSet // {
      extendModules = args: withExtraAttrs (finalSet.extendModules args);
      grizz = { inherit settings overlays; };
    }) // (extraAttrHook finalSet);

    configuration = lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          networking.hostName = name;
          nixpkgs.overlays = [ (defaultOverlay pkgs) ] ++ overlays;
          nixpkgs.hostPlatform = hostPlatform;
        })
      ]
      ++ lib.optional (buildPlatform != null) { nixpkgs.buildPlatform = buildPlatform; }
      ++ modules;
    };
  in withExtraAttrs configuration;
in
{
  inherit mkNixOS;
}
