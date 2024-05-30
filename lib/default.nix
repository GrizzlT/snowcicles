{ self, nixpkgs, ... }@inputs:
let
  hosts = import ./hosts.nix inputs;
  hm = import ./hm.nix inputs;
  nixosOverlay = import ./nixos-overlay.nix inputs;
  hmOverlay = import ./hm-overlay.nix inputs;

  mkProfiles = import ./profiles.nix inputs;

  lib = nixpkgs.lib;
in
{
  inherit nixosOverlay hmOverlay mkProfiles;

  mergeRecursive = builtins.foldl' lib.recursiveUpdate {};
}
// hosts
// hm
