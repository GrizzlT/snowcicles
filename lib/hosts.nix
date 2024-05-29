{ self, ... }@inputs:
let
  libOverlay = self': super': {
    grizz = self.lib.nixosOverlay self' super';
  };

  lib = inputs.nixpkgs.lib.extend libOverlay; # NOTE: in the latest version, this should be enough to achieve the hack below
  inherit (self.lib) mergeRecursive;

  mkNixOS = name: settings: let
    # include flake lib
    # unstable nixpkgs -> same platform + overlays
    defaultOverlay = pkgs: self': super: {
      lib = super.lib.extend libOverlay;
      unstable = import inputs.unstable ({
        inherit (pkgs) config;
        overlays = [ (_: super': {
          lib = super'.lib.extend libOverlay;
        }) ] ++ overlays;
      } // (if (buildPlatform != null && buildPlatform != hostPlatform) then {
        localSystem = buildPlatform;
        crossSystem = hostPlatform;
      } else {
        localSystem = hostPlatform;
      }));
    };

    # all modules to include by default
    modules = lib.pipe (builtins.readDir "${self}/modules/nixos/options") [
      (lib.filterAttrs (_: v: v == "regular"))
      (lib.mapAttrsToList (n: _: import "${self}/modules/nixos/options/${n}"))
    ]
      ++ lib.pipe (builtins.readDir "${self}/modules/nixos/configs") [
      (lib.filterAttrs (_: v: v == "regular"))
      (lib.mapAttrsToList (n: _: import "${self}/modules/nixos/configs/${n}"))
    ]
      ++ (lib.optional settings.agenix or true inputs.agenix.nixosModules.default)
      ++ (lib.optional settings.generators or true inputs.nixos-generators.nixosModules.all-formats)
      ++ (settings.modules or []);

    # overlays to be applied to nixpkgs
    overlays = []
      ++ (lib.optional settings.agenix or true inputs.agenix.overlays.default)
      ++ (lib.optional settings.home-manager or true (import "${inputs.home-manager}/overlay.nix"))
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
        grizz = { inherit settings; };
      }
      (extraAttrHook finalSet)
    ];

    configuration = lib.nixosSystem {
      inherit lib; # HACK: nixpkgs 23.11 does not auto include here lib from which `nixosSystem` is called
      modules = [
        ({ pkgs, lib, ... }: {
          networking.hostName = name;
          nixpkgs.overlays = [ (defaultOverlay pkgs) ] ++ overlays;
          nixpkgs.hostPlatform = hostPlatform;
          grizz.settings = settings;
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
  }@args: all: builtins.mapAttrs (name: opts: mkNixOS name (mergeRecursive [
    {
      # attrHook: apply specialized after default
      withExtra = config:
        let
          general = defaultAttrHook all name config;
          specialized = opts.withExtra or (_: {}) (lib.recursiveUpdate config general);
        in
          lib.recursiveUpdate general specialized;

      # add default downstream modules
      modules = opts.modules or [] ++ (defaultModules all name);
      # add default downstream overlays
      overlays = opts.overlays or [] ++ (defaultOverlays all name);
    }
    (builtins.removeAttrs args [ "defaultAttrHook" "defaultModules" "defaultOverlays" ])
    (builtins.removeAttrs opts [ "withExtra" ])
  ])) all;
in
{
  inherit mkNixOS mkNixOSes;
}
