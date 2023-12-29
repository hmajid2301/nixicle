{
  pkgs,
  config,
  inputs,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.wms.hyprland;
in {
  imports = [
    ./config
    ./gammastep.nix
    ./kanshi.nix
    ./rofi.nix
    ./swaync
    ./swaylock.nix
    ./theme
    ./waybar
    ./wlogout.nix
    ./xdg.nix

    inputs.hyprland-nix.homeManagerModules.default
  ];

  options.modules.wms.hyprland = {
    enable = mkEnableOption "enable hyprland window manager";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = rec {
      MOZ_ENABLE_WAYLAND = 1;
      QT_QPA_PLATFORM = "wayland";
      LIBSEAT_BACKEND = "logind";
    };

    dconf.settings = {
      "org/gnome/desktop/privacy" = {
        remember-recent-files = false;
      };
    };

    home.packages = with pkgs; [
      mplayer
      mtpfs
      jmtpfs
      brightnessctl
      xdg-utils
      wl-clipboard
      pamixer
      playerctl
      sway-contrib.grimshot

      impression
      raider
      helvum
      gnome.gnome-font-viewer
      gnome.gnome-characters
      gnome.sushi
      gnome.nautilus
      gnome.gnome-disk-utility
      gnome.totem
      gnome.gucharmap
      gnome.gvfs
      gnome.gnome-logs
      loupe
      gnome-text-editor
      pavucontrol

      inputs.nwg-displays.packages."${pkgs.system}".default
      inputs.hypr-contrib.packages.${pkgs.system}.grimblast
      pkgs.xdg-desktop-portal-hyprland
      pkgs.satty
    ];

    nix.settings = {
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
  };
}
