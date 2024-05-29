{ pkgs, ... }:
{
  home.packages = with pkgs; [
    neofetch
    jq
    fd
    unzip
    zip
    mosh
    cachix
  ];
}
