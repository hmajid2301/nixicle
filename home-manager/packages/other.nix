{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    htop
    ranger
    unzip
    pavucontrol
    gnupg
    ferdium

    # other
    any-nix-shell
    brotab
    brave
    betterdiscord-installer
    discord
    showmethekey
  ];
}


