{ lib, config, ... }:
let
  cfg = config.services.rayfish;
in
{
  config = lib.mkIf config.services.rayfish.enable {
    environment.systemPackages = [ cfg.package ];
    systemd.packages = [ cfg.package ];
    systemd.services.rayfish = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = lib.optional config.networking.resolvconf.enable config.networking.resolvconf.package;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} daemon";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
