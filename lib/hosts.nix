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
    modules = []
      ++ (lib.optional settings.agenix or true inputs.agenix.nixosModules.default)
      ++ (settings.modules or []);

    # overlays to be applied to nixpkgs
    overlays = []
      ++ (lib.optional settings.agenix or true inputs.agenix.overlays.default)
      ++ (settings.overlays or []);

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
      inherit lib; # HACK: nixpkgs 23.11 does not auto include here lib from which `nixosSystem` is called
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

  # General wrapper for downstream usage
  #
  # Applies defaults per configuration set. This option allows for parametrized
  # defaults based on the configuration name and the entire set.
  mkNixOSes = {
    defaultAttrHook ? (all: name: config: {}),
    defaultModules ? (all: name: []),
    defaultOverlays ? (all: name: []),
    ...
  }@args: all: let
    modulesFn = defaultModules all;
    overlaysFn = defaultOverlays all;
    attrHook = defaultAttrHook all;
  in builtins.mapAttrs (name: opts: mkNixOS name (opts // {
    # attrHook: apply specialized after default
    withExtra = config:
      let
        general = attrHook name config;
        specialized = opts.withExtra or (_: {}) (lib.recursiveUpdate config general);
      in
        lib.recursiveUpdate general specialized;

    # add default downstream modules
    modules = opts.modules or [] ++ (modulesFn name);
    # add default downstream overlays
    overlays = opts.overlays or [] ++ (overlaysFn name);
  } // lib.optionalAttrs (args?defaultHostPlatform) {
    # add default downstream hostPlatform
    hostPlatform = opts.hostPlatform or args.defaultHostPlatform;
  })) all;
in
{
  inherit mkNixOS;
  inherit mkNixOSes;
}
