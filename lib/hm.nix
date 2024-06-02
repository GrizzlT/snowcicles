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
  mkHmManagers = { hosts ? {}, defaults ? (_: _: _: {}) }: all: let
    singleHm = name: host: opts: let
      settings = (self: let
        defaultOpts = defaults all name self;
      in mergeRecursive [
        (builtins.removeAttrs defaultOpts [ "withExtra" "modules" "overlays" ])
        {
          hostname = host.name;
          system = host.value;

          withExtra = config:
            let
              general = defaultOpts.withExtra or (_: {}) config;
              specialized = opts.withExtra or (_: {}) (lib.recursiveUpdate config general);
            in
              lib.recursiveUpdate general specialized;
          modules = defaultOpts.modules or [] ++ opts.modules or [];
          overlays = defaultOpts.overlays or [] ++ opts.overlays or [];
        }
        (builtins.removeAttrs opts [ "withExtra" "hosts" "modules" "overlays" ])
      ]) settings;
    in {
      name = "${name}@${host.name}";
      value = mkHomeManager "${name}@${host.name}" settings;
    };
  in builtins.listToAttrs (lib.foldlAttrs (acc: name: opts: let
    configHosts = lib.attrsToList (hosts // opts.hosts or {});
    configs = map (host: singleHm name host opts) configHosts;
  in acc ++ configs) [] all);
in
{
  inherit mkHomeManager mkHmManagers;
}
