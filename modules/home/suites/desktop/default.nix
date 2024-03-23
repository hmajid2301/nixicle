{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.suites.desktop;
in {
  options.suites.desktop = {
    enable = mkEnableOption "Enable desktop suite";
  };

  config = mkIf cfg.enable {
    suites = {
      common.enable = true;
      development.enable = true;
    };

    services = {
      nixicle.kdeconnect.enable = true;
      spotify.enable = true;
    };
    desktops.addons.xdg.enable = true;

    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      QT_QPA_PLATFORM = "wayland;xcb";
      LIBSEAT_BACKEND = "logind";
    };

    # TODO: move this to somewhere
    home.packages = with pkgs; [
      mplayer
      mtpfs
      jmtpfs
      brightnessctl
      xdg-utils
      wl-clipboard
      pamixer
      playerctl

      grimblast
      slurp
      sway-contrib.grimshot
      pkgs.xdg-desktop-portal-hyprland
      pkgs.satty
    ];
  };
}
