{ lib, config, ... }:
{
  config = lib.mkIf config.grizz.settings.tailscale or true {
    services.tailscale.enable = true;
  };
}

