{ config, pkgs, ... }:

let
  charasay = pkgs.callPackage ./packages/chara.nix {};
in
{
  home.packages = with pkgs; [
    # core
    htop
    neovim
    ranger
    wl-clipboard
    unzip

    # custom, will move to nix packages
    charasay

    # other
    brotab
    brave
    betterdiscord-installer
    discord
    mullvad-vpn
    showmethekey
  ];
}

