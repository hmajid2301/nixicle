{ inputs, outputs, config, ... }:
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
}
