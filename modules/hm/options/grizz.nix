{ lib, ... }:
{
  options.grizz.settings = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = {};
  };
}
