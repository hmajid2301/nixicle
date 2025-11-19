{delib, inputs, ...}:
delib.host {
  name = "dell";
  rice = "catppuccin";

  myconfig = {
    hosts.dell = {
      type = "desktop";
      isDesktop = true;
      system = "x86_64-linux";
    };
  };

  nixos = {pkgs, lib, config, myconfig, ...}: lib.mkIf (myconfig.host.name == "dell") {
    # Dell system configuration
    # Note: Hardware-configuration.nix should be generated on the device

    system.stateVersion = "23.11";
  };

  home = {config, pkgs, lib, myconfig, ...}: let
    screensharing = pkgs.writeScriptBin "screensharing" ''
      #!/usr/bin/env bash
      sleep 1
      killall -e xdg-desktop-portal-hyprland 2>/dev/null || true
      killall -e xdg-desktop-portal-wlr 2>/dev/null || true
      killall xdg-desktop-portal 2>/dev/null || true
      # Use NixOS paths instead of hardcoded /usr/libexec
      if command -v xdg-desktop-portal-hyprland >/dev/null 2>&1; then
        xdg-desktop-portal-hyprland &
      fi
      sleep 2
      if command -v xdg-desktop-portal >/dev/null 2>&1; then
        xdg-desktop-portal &
      fi
    '';
  in lib.mkIf (myconfig.host.name == "dell") {
    nixGL = {
      inherit (inputs.nixgl) packages;
      defaultWrapper = "mesa";
    };

    programs = {
      firefox.package = config.lib.nixGL.wrap pkgs.firefox;
      # ghostty.package = config.lib.nixGL.wrap pkgs.ghostty;
    };

    roles = {
      desktop.enable = true;
    };

    home = {
      packages = with pkgs; [
        semgrep
        pre-commit
        bun

        # INFO: Packages stylix usually installs but doesn't work with gnome 46 at the moment.
        # So we are installing them here and we will manually set them.
        pkgs.nixicle.monolisa
        pkgs.noto-fonts-color-emoji
        pkgs.noto-fonts
        pkgs.source-serif
        pkgs.nerd-fonts.symbols-only
        pkgs.dejavu_fonts
        pkgs.liberation_ttf
        screensharing
        nwg-displays
        (lib.hiPrio (config.lib.nixGL.wrap totem))
      ];
    };

    # TODO: Don't hardcode UID - use dynamic resolution like: "/run/user/${toString config.users.users.${config.home.username}.uid}/secrets"
    # This breaks if user gets different UID on different systems
    sops.defaultSymlinkPath = lib.mkForce "/run/user/1003/secrets";
    sops.defaultSecretsMountPoint = lib.mkForce "/run/user/1003/secrets.d";

    stylix = lib.mkForce {
      enable = false;
      autoEnable = false;
      targets.gnome.enable = false;
      targets.gnome.useWallpaper = false;
      image = null;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    };

    programs.ghostty.package = config.lib.nixGL.wrap pkgs.ghostty;

    desktops = {
      hyprland = {
        enable = true;
        execOnceExtras = [
          "warp-taskbar"
          "blueman-applet"
          "${screensharing}/bin/screensharing"
          "nm-applet"
        ];
      };

      # gnome.enable = true;
    };

    fonts.fontconfig.enable = true;

    xdg = {
      mimeApps.defaultApplications = lib.mkForce {
        "text/html" = [ "google-chrome.desktop" ];
        "x-scheme-handler/http" = [ "google-chrome.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome.desktop" ];
        "x-scheme-handler/about" = [ "google-chrome.desktop" ];
        "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
      };

      configFile."environment.d/envvars.conf".text = ''
        PATH="$PATH:${config.home.homeDirectory}/.nix-profile/bin"
      '';

      # Override desktop entry to use NixGL-wrapped ghostty
      desktopEntries.ghostty = {
        name = "Ghostty";
        comment = "A terminal emulator";
        exec = "${config.home.homeDirectory}/.nix-profile/bin/ghostty";
        icon = "com.mitchellh.ghostty";
        categories = [
          "System"
          "TerminalEmulator"
        ];
        terminal = false;
        startupNotify = true;
        settings = {
          StartupWMClass = "com.mitchellh.ghostty";
          Keywords = "terminal;tty;pty;";
          X-GNOME-UsesNotifications = "true";
        };
      };

      # Override desktop entry to use NixGL-wrapped totem
      # Using dataFile to override the existing desktop file from the totem package
      dataFile."applications/org.gnome.Totem.desktop".text = ''
        [Desktop Entry]
        Name=Videos
        Comment=Play movies
        Exec=${config.home.homeDirectory}/.nix-profile/bin/totem %U
        Icon=org.gnome.Totem
        Terminal=false
        Type=Application
        Categories=GNOME;GTK;AudioVideo;Player;Video;
        MimeType=application/ogg;application/x-ogg;audio/ogg;audio/vorbis;audio/x-vorbis;audio/x-vorbis+ogg;video/ogg;video/x-ogm;video/x-ogm+ogg;video/x-theora+ogg;video/x-theora;application/x-extension-m4a;application/x-extension-mp4;audio/aac;audio/m4a;audio/mp1;audio/mp2;audio/mp3;audio/mpeg;audio/mpeg2;audio/mpeg3;audio/mpegurl;audio/mpg;audio/rn-mpeg;audio/scpls;audio/x-m4a;audio/x-mp1;audio/x-mp2;audio/x-mp3;audio/x-mpeg;audio/x-mpeg2;audio/x-mpeg3;audio/x-mpegurl;audio/x-mpg;audio/x-scpls;video/3gp;video/3gpp;video/3gpp2;video/avi;video/divx;video/dv;video/fli;video/flv;video/mp2t;video/mp4;video/mp4v-es;video/mpeg;video/msvideo;video/quicktime;video/vnd.divx;video/vnd.mpegurl;video/vnd.rn-realvideo;video/webm;video/x-avi;video/x-flc;video/x-fli;video/x-flv;video/x-m4v;video/x-matroska;video/x-mpeg2;video/x-mpeg3;video/x-ms-afs;video/x-ms-asf;video/x-msvideo;video/x-ms-wmv;video/x-ms-wmx;video/x-ms-wvxvideo;video/x-nsv;video/x-theora+ogg;video/x-totem-stream;application/vnd.rn-realmedia;application/vnd.rn-realmedia-vbr;
        StartupNotify=true
        X-GNOME-UsesNotifications=true
      '';

      configFile."fontconfig/conf.d/99-custom-fonts.conf".text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <!-- Default sans-serif font -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>sans-serif</string>
            </test>
            <edit name="family" mode="assign">
              <string>Noto Sans</string>
            </edit>
          </match>

          <!-- Default serif font -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>serif</string>
            </test>
            <edit name="family" mode="assign">
              <string>Source Serif</string>
            </edit>
          </match>

          <!-- Default monospace font -->
          <match target="pattern">
            <test qual="any" name="family">
              <string>monospace</string>
            </test>
            <edit name="family" mode="assign">
              <string>MonoLisa</string>
            </edit>
          </match>

          <!-- Monospace fallback chain -->
          <match target="pattern">
            <test name="family">
              <string>monospace</string>
            </test>
            <edit name="family" mode="append">
              <string>Symbols Nerd Font</string>
            </edit>
          </match>

          <match target="pattern">
            <test name="family">
              <string>monospace</string>
            </test>
            <edit name="family" mode="append">
              <string>DejaVu Sans Mono</string>
            </edit>
          </match>

          <!-- Sans-serif fallback chain -->
          <match target="pattern">
            <test name="family">
              <string>sans-serif</string>
            </test>
            <edit name="family" mode="append">
              <string>DejaVu Sans</string>
            </edit>
          </match>

          <match target="pattern">
            <test name="family">
              <string>sans-serif</string>
            </test>
            <edit name="family" mode="append">
              <string>Symbols Nerd Font</string>
            </edit>
          </match>


          <!-- Force emoji rendering -->
          <match target="pattern">
            <test name="family">
              <string>emoji</string>
            </test>
            <edit name="family" mode="assign">
              <string>Noto Color Emoji</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };

    cli.tools = {
      git = {
        allowedSigners = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUF0LHH63pGkd1m7FGdbZirVXULDS5WSDzerJ0sskoq haseeb.majid@nala.money";
        email = "haseeb.majid@nala.money";
      };
    };

    nixicle.user = {
      enable = true;
      name = "haseebmajid";
    };

    home.stateVersion = "23.11";
  };
}
