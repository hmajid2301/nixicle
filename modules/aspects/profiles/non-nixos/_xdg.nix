{ config, ... }:
{
  xdg = {
    configFile = {
      "xdg-desktop-portal/niri-portals.conf".text = ''
        [preferred]
        default=gnome;gtk;
        org.freedesktop.impl.portal.FileChooser=gtk;
        org.freedesktop.impl.portal.Access=gtk;
        org.freedesktop.impl.portal.Notification=gtk;
        org.freedesktop.impl.portal.Secret=gnome-keyring;
      '';

      "systemd/user/app-com.mitchellh.ghostty.service.d/initial-window.conf".text = ''
        [Service]
        ExecStart=
        ExecStart=${config.programs.ghostty.package}/bin/ghostty --gtk-single-instance=true
      '';

      "environment.d/envvars.conf".text = ''
        PATH="$PATH:${config.home.homeDirectory}/.nix-profile/bin"
        XDG_DATA_DIRS="/usr/share/gnome:/usr/local/share:/usr/share:$XDG_DATA_DIRS"
        WAYLAND_DISPLAY=wayland-0
        XDG_CURRENT_DESKTOP=niri
        XDG_SESSION_TYPE=wayland
        MOZ_ENABLE_WAYLAND=1
        _JAVA_AWT_WM_NONREPARENTING=1
        MESA_LOADER_DRIVER_OVERRIDE=iris
        intel_idle.max_cstate=1
      '';
    };

    dataFile."applications/google-chrome.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Google Chrome
      GenericName=Web Browser
      Comment=Access the Internet
      Exec=${config.home.homeDirectory}/.nix-profile/bin/google-chrome %U
      StartupNotify=true
      Terminal=false
      Icon=google-chrome
      Type=Application
      Categories=Network;WebBrowser;
      MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/google-chrome;
      Actions=new-window;new-private-window;

      [Desktop Action new-window]
      Name=New Window
      Exec=${config.home.homeDirectory}/.nix-profile/bin/google-chrome

      [Desktop Action new-private-window]
      Name=New Incognito Window
      Exec=${config.home.homeDirectory}/.nix-profile/bin/google-chrome --incognito
    '';

    dataFile."applications/com.mitchellh.ghostty.desktop".text = ''
      [Desktop Entry]
      Version=1.0
      Name=Ghostty
      Type=Application
      Comment=A terminal emulator
      Exec=${config.home.homeDirectory}/.nix-profile/bin/ghostty --gtk-single-instance=true
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
      Exec=${config.home.homeDirectory}/.nix-profile/bin/ghostty
    '';
  };
}
