{ lib, config, ... }:
{
  config = lib.mkIf config.grizz.settings.tailscale {
    services.tailscale.enable = true;
  };
}

