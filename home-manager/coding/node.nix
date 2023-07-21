{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodePackages.pnpm
    nodejs
  ];
}
