selfLib:
final: prev: {
  lib = final.lib // {
    grizz = selfLib;
  };
}
