{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    htop
    ranger
    unzip
    pavucontrol
    gnupg

    # other
    any-nix-shell
    brotab
    brave
    betterdiscord-installer
    discord
    mullvad-vpn
    showmethekey
  ];
}


