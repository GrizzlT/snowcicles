{ self, nixpkgs, ... }@inputs:
let
  hosts = import ./hosts.nix inputs;
  nixos = import ./nixos.nix inputs;
in
{
  inherit nixos;
}
// hosts
