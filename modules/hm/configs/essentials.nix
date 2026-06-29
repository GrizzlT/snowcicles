{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jq
    fd
    unzip
    zip
    mosh
    cachix
  ];
}
