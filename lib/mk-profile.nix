{ buildEnv, mkShell, writeShellScriptBin, basePathEnvDefault ? "GRIZZ_PROFILES" }:
({
  name,
  nativeBuildInputs ? [],
  buildInputs ? [],
  ...
}@args:

let
  args' = builtins.removeAttrs args [ "basePathEnv" ];

  env = buildEnv (args' // {
    name = "profile-${name}";
  });
  basePath = args.basePathEnv or basePathEnvDefault;
in
env // {
  switch = writeShellScriptBin "switch" ''
    nix-env --set ${env} "$@" --profile ''${${basePath}:-.}/${name}
  '';
  rollback = writeShellScriptBin "rollback" ''
    nix-env --rollback "$@" --profile ''${${basePath}:-.}/${name}
  '';
  shell = mkShell {
    buildInputs = args'.buildInputs ++ args'.paths;
    nativeBuildInputs = args'.nativeBuildInputs;
  };
})
