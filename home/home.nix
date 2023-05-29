{ config, inputs, pkgs, system, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "haseeb";
  home.homeDirectory = "/home/haseeb";
  
  imports = [
    ./modules/alacritty.nix
    ./modules/coding.nix
    ./modules/fish.nix
    ./modules/firefox.nix
    ./modules/gnome.nix
    ./modules/git.nix
    ./modules/nvim.nix
    ./modules/tmux.nix
    ./modules/packages.nix
    ./modules/unix_tools.nix
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This zzhelps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "22.11"; # Please read the comment before changing.

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}

