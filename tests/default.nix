{ ... }@inputs:
let
  hosts = import ./hosts.nix inputs;
  # hm = import ./hm.nix inputs;
in
{
  inherit hosts;
}
