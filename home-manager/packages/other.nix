{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nvtop-amd
    htop
    ranger
    lf
    ctpv
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


