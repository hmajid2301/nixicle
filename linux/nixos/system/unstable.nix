{ config, pkgs, ...}:
let
  baseconfig = { allowUnfree = true; };
  unstable = import <nixpkgs-unstable> { config = baseconfig; };
in {
  environment.systemPackages = with pkgs; [
    unstable.gradience
    unstable.catppuccin-papirus-folders
    unstable.catppuccin-cursors.frappeLavender
  ];
}

