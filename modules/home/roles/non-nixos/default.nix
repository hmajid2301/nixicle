{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.roles.non-nixos;
in
{
  options.roles.non-nixos = {
    enable = mkEnableOption "Enable non-NixOS system configurations (Ubuntu, Debian, Fedora, etc.)";
  };

  config = mkIf cfg.enable {
    # NixGL configuration
    nixGL = {
      inherit (inputs.nixgl) packages;
      defaultWrapper = "mesa";
    };

    programs = {
      firefox.package = config.lib.nixGL.wrap pkgs.firefox;
    };

    home.packages = with pkgs; [
      (lib.hiPrio (config.lib.nixGL.wrap totem))
    ];

    # Desktop entries with nixGL wrappers
    xdg.dataFile."applications/com.mitchellh.ghostty.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Name=Ghostty
        Type=Application
        Comment=A terminal emulator
        Exec=nixGLIntel ${config.home.homeDirectory}/.nix-profile/bin/ghostty --gtk-single-instance=true
        Icon=com.mitchellh.ghostty
        Categories=System;TerminalEmulator;
        Keywords=terminal;tty;pty;
        StartupNotify=true
        StartupWMClass=com.mitchellh.ghostty
        Terminal=false
        Actions=new-window;
        X-GNOME-UsesNotifications=true
        X-TerminalArgExec=-e
        X-TerminalArgTitle=--title=
        X-TerminalArgAppId=--class=
        X-TerminalArgDir=--working-directory=
        X-TerminalArgHold=--wait-after-command

        [Desktop Action new-window]
        Name=New Window
        Exec=nixGLIntel ${config.home.homeDirectory}/.nix-profile/bin/ghostty
      '';

    # Chrome/Chromium flags for better Wayland/OpenGL support
    xdg.configFile."chrome-flags.conf".text = ''
      --enable-features=VaapiVideoDecoder
      --use-gl=desktop
      --enable-zero-copy
    '';

    # Wayland environment variables for systemd services
    # These are needed for Chrome, Android Studio, and other GUI apps
    xdg.configFile."environment.d/envvars.conf".text = ''
      PATH="$PATH:${config.home.homeDirectory}/.nix-profile/bin"
      XDG_DATA_DIRS="/usr/share/gnome:/usr/local/share:/usr/share:$XDG_DATA_DIRS"
      
      # Wayland/Niri environment for applications launched from systemd services
      WAYLAND_DISPLAY=wayland-0
      XDG_CURRENT_DESKTOP=niri
      XDG_SESSION_TYPE=wayland
      MOZ_ENABLE_WAYLAND=1
      
      # Note: NIRI_SOCKET can't be set here as it's dynamic per niri instance
      # Apps needing niri IPC must be launched from within niri session
    '';
  };
}
