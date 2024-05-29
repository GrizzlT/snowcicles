{ self, ... }@inputs:
let
  libOverlay = self': super': {
    grizz = self.lib.hmOverlay self' super';
  };

  lib = inputs.nixpkgs.lib.extend libOverlay;
  inherit (self.lib) mergeRecursive;

  mkHomeManager = name: settings: let
    # include flake lib
    # unstable nixpkgs -> same platform + overlays
    defaultOverlay = pkgs: self': super: {
      lib = super.lib.extend libOverlay;
      unstable = import inputs.unstable ({
        inherit (pkgs) config system;
        overlays = [ (_: super': {
          lib = super'.lib.extend libOverlay;
        }) ] ++ overlays;
      });
    };

    modules = lib.pipe (builtins.readDir "${self}/modules/hm/options") [
      (lib.filterAttrs (_: v: v == "regular"))
      (lib.mapAttrsToList (n: _: import "${self}/modules/hm/options/${n}"))
    ]
      ++ lib.pipe (builtins.readDir "${self}/modules/hm/configs") [
      (lib.filterAttrs (_: v: v == "regular"))
      (lib.mapAttrsToList (n: _: import "${self}/modules/hm/configs/${n}"))
    ]
      ++ (settings.modules or []);

    overlays = []
      ++ (settings.overlays or []);

    system = settings.system or "x86_64-linux";

    extraAttrHook = settings.withExtra or (_: {});

    withExtraAttrs = finalSet: mergeRecursive [
      finalSet
      {
        extendModules = args: withExtraAttrs (finalSet.extendModules args);
        grizz = { inherit settings; };
      }
      (extraAttrHook finalSet)
    ];

    configuration = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      inherit lib;
      modules = [
        ({ pkgs, lib, ... }: {
          nixpkgs.overlays = [ (defaultOverlay pkgs) ] ++ overlays;
          grizz.settings = settings;
        })
      ]
        ++ modules;
    };
  in
    withExtraAttrs configuration;

  # General wrapper for downstream usage
  #
  # Applies defaults per configuration set. This option allows for parametrized
  # defaults based on the configuration name and the entire set.
  mkHmManagers = {
    defaultAttrHook ? (all: name: config: {}),
    defaultModules ? (all: name: host: []),
    defaultOverlays ? (all: name: host: []),
    ...
  }@args: all: let
    singleHm = name: host: opts: {
      name = "${name}@${host.name}";
      value = mkHomeManager "${name}@${host.name}" (mergeRecursive [
        (builtins.removeAttrs args [ "defaultAttrHook" "defaultModules" "defaultOverlay" "hosts" ])
        {
          withExtra = config:
            let
              general = defaultAttrHook all name config;
              specialized = opts.withExtra or (_: {}) (lib.recursiveUpdate config general);
            in
              lib.recursiveUpdate general specialized;
          modules = opts.modules or [] ++ (defaultModules all name host);
          overlays = opts.overlays or [] ++ (defaultOverlays all name host);
          hostname = host.name;
        }
        (builtins.removeAttrs opts [ "withExtra" "hosts" ])
      ]);
    };
  in builtins.listToAttrs (lib.foldlAttrs (acc: name: opts: let
    hosts = lib.attrsToList (args.hosts or {} // opts.hosts or {});
    configs = map (host: singleHm name host (opts // {
      system = host.value;
    })) hosts;
  in acc ++ configs) [] all);
in
{
  inherit mkHomeManager mkHmManagers;
}
