{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    luarocks
  ];
}
