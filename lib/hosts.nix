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
      ++ (settings.overlays or []);

    # cross compilation support
    hostPlatform = settings.hostPlatform or (settings.system or { system = "x86_64-linux"; });
    buildPlatform = if (settings ? hostPlatform) then settings.buildPlatform or "x86_64-linux" else settings.buildPlatform or null;

    # extra attrs
    extraAttrHook = settings.withExtra or (_: {});

    settingsToInclude = builtins.removeAttrs settings [ "_callInternal" ];

    # Enable configuration extendModules
    # add grizz metadata
    withExtraAttrs = finalSet: mergeRecursive [
      finalSet
      {
        extendModules = args: withExtraAttrs (finalSet.extendModules args);
        grizz = { settings = settingsToInclude; };
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
          grizz.settings = settingsToInclude;
        })
      ]
        ++ lib.optional (buildPlatform != null) { nixpkgs.buildPlatform = buildPlatform; }
        ++ modules;
    };
  in
    lib.warnIfNot settings._callInternal or false ''
      `mkNixOS` was probably called by accident, consider using `mkNixOSes` instead.
      If this function was used on purpose, make sure to pass `_callInternal` as true.
    '' (withExtraAttrs configuration);

  # General wrapper for downstream usage
  #
  # Applies defaults per configuration set. This option allows for parametrized
  # defaults based on the configuration name and the entire set.
  mkNixOSes = defaultsFn: all: builtins.mapAttrs (name: opts: let
    settings = (self: let
      defaults = defaultsFn all name self;
    in mergeRecursive [
      {
        agenix = true;
        generators = true;
        system = "x86_64-linux";
        _callInternal = true; # avoid accidentally calling exposed `mkNixOS` function.

        withExtra = config:
          let
            general = defaults.withExtra or (_: {}) config;
            specialized = opts.withExtra or (_: {}) (lib.recursiveUpdate config general);
          in
            lib.recursiveUpdate general specialized;
        modules = defaults.modules or [] ++ opts.modules or [];
        overlays = defaults.overlays or [] ++ opts.overlays or [];
      }
      (builtins.removeAttrs defaults [ "withExtra" "modules" "overlays" "_callInternal" ])
      (builtins.removeAttrs opts [ "withExtra" "modules" "overlays" "_callInternal" ])
    ]) settings;
  in mkNixOS name settings) all;
in
{
  inherit mkNixOS mkNixOSes;
}
