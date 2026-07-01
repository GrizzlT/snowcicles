{ lib, pkgs, ... }:
{
  options.services.rayfish = {
    enable = lib.mkEnableOption "Rayfish P2P Mesh VPN";

    package = lib.mkPackageOption pkgs "rayfish" { };
  };
}
