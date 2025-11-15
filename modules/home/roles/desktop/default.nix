{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
with lib;
let
  cfg = config.roles.desktop;
in
{
  options.roles.desktop = {
    enable = mkEnableOption "Enable desktop suite";
  };

  config = mkIf cfg.enable {
    roles = {
      common.enable = true;
      development.enable = true;
    };

    # Fixes tray icons: https://github.com/nix-community/home-manager/issues/2064#issuecomment-887300055
    systemd.user.targets.tray = {
      Unit = {
        Description = "Home Manager System Tray";
        Requires = [ "graphical-session-pre.target" ];
      };
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
      EDITOR = "nixCats";
      MANPAGER = "nixCats +Man!";
    };

    # Desktop utilities
    home.packages = with pkgs; [
      ddcutil # Monitor control via DDC/CI
      mplayer # Media player
      mtpfs # MTP filesystem support
      jmtpfs # Java MTP filesystem
      brightnessctl # Brightness control
      xdg-utils # XDG utilities
      wl-clipboard # Wayland clipboard utilities
      clipse # Clipboard manager
      pamixer # PulseAudio mixer
      playerctl # Media player controller

      grimblast
      slurp
      sway-contrib.grimshot
      pkgs.satty
    ];
  };
}
