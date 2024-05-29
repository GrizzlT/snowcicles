{ lib, ... }:
{
  options.grizz.settings = lib.mkOption {
    type = lib.types.anything;
    default = {};
  };
}
