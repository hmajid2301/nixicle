{ inputs, outputs, ... }:
{
  imports = [
    ./global
    ./features/browsers/firefox.nix
    ./features/terminals/alacritty.nix
    ./features/shells/fish.nix
    ./features/desktops/hyprland
    ./features/gtk.nix
    ./features/games
  ];

  colorscheme = inputs.nix-colors.colorSchemes.catppuccin-frappe;
  home.sessionVariables.GTK_THEME = "catppuccin";

  #  ------   -----   ------
  # | DP-3 | | DP-1| | DP-2 |
  #  ------   -----   ------
  #monitors = [
  #  {
  #    name = "DP-3";
  #    width = 1920;
  #    height = 1080;
  #    noBar = true;
  #    x = 0;
  #    workspace = "3";
  #    enabled = false;
  #  }
  #  {
  #    name = "DP-1";
  #    width = 2560;
  #    height = 1080;
  #    refreshRate = 75;
  #    x = 1920;
  #    workspace = "1";
  #  }
  #  {
  #    name = "DP-2";
  #    width = 1920;
  #    height = 1080;
  #    noBar = true;
  #    x = 4480;
  #    workspace = "2";
  #  }
  #];
}
