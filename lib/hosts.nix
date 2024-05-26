{ self, ... }@inputs:
let
  libOverlay = _: _: {
    grizz = self.lib.nixos;
  };

  lib = inputs.nixpkgs.lib.extend libOverlay; # NOTE: in the latest version, this should be enough to achieve the hack below
  mergeRecursive = builtins.foldl' lib.recursiveUpdate {};

  mkNixOS = name: settings: let
    # include flake lib
    # unstable nixpkgs -> same platform + overlays
    defaultOverlay = pkgs: self0: super: {
      lib = super.lib.extend libOverlay;
      unstable = import inputs.unstable ({
        inherit (pkgs) config;
        overlays = [ (self0: super: {
          lib = super.lib.extend libOverlay;
        }) ] ++ overlays;
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
    withExtraAttrs = finalSet: mergeRecursive [
      finalSet
      {
        extendModules = args: withExtraAttrs (finalSet.extendModules args);
        grizz = { inherit settings overlays; };
      }
      (extraAttrHook finalSet)
    ];

    configuration = lib.nixosSystem {
      inherit lib; # HACK: this version of nixpkgs doesn't include lib from which `nixosSystem` is called
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

  mkNixOSes = {
    defaultAttrHook ? (all: _: {}),
    defaultModules ? (all: []),
    defaultOverlays ? (all: []),
    ...
  }@args: all: builtins.mapAttrs (name: opts: mkNixOS name (opts // {
    withExtra = config: let
      general = defaultAttrHook all config;
      specialized = opts.withExtra or (_: {}) (lib.recursiveUpdate config general);
    in lib.recursiveUpdate general specialized;
    modules = opts.modules or [] ++ (defaultModules all);
    overlays = opts.overlays or [] ++ (defaultOverlays all);
  } // lib.optionalAttrs (args?defaultHostPlatform) {
    hostPlatform = args.defaultHostPlatform;
  })) all;
in
{
  inherit mkNixOS;
  inherit mkNixOSes;
}
