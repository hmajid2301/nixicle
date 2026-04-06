{ den, ... }:
{
  den.aspects.desktop = {
    includes = [
      den.aspects.common
      den.aspects.development
      den.aspects.niri
      den.aspects.audio
      den.aspects.vpn
    ];

    nixos = { lib, pkgs, ... }: {
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = false;
          settings.General.Experimental = true;
        };
        # Logitech wireless mouse
        logitech.wireless = {
          enable = true;
          enableGraphical = true;
        };
        # ZSA keyboards (Moonlander, Voyager, etc.)
        keyboard.zsa.enable = true;
      };
      services = {
        upower.enable = true;
        blueman.enable = true;
        avahi = {
          enable = true;
          nssmdns4 = true;
          publish = {
            enable = true;
            addresses = true;
            domain = true;
            hinfo = true;
            userServices = true;
            workstation = true;
          };
        };
      };
      environment.systemPackages = with pkgs; [
        solaar
      ];
      services.udev.packages = with pkgs; [
        logitech-udev-rules
        solaar
      ];
      boot.plymouth.enable = true;
      boot.kernelParams = [ "quiet" "splash" "loglevel=3" "udev.log_level=0" ];
      programs.nh = {
        enable = true;
        clean.enable = true;
        clean.extraArgs = "--keep-since 4d --keep 3";
        flake = "/home/haseeb/nixicle";
      };
      nix.gc.automatic = lib.mkForce false;
    };

    homeManager = { pkgs, config, ... }: {
      systemd.user.targets.tray = {
        Unit = {
          # tray icons require graphical-session-pre: https://github.com/nix-community/home-manager/issues/2064
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };
      xdg.desktopEntries = {
        "org.kde.kdeconnect.sms" = { exec = ""; name = "KDE Connect SMS"; settings.NoDisplay = "true"; };
        "org.kde.kdeconnect.nonplasma" = { exec = ""; name = "KDE Connect Indicator"; settings.NoDisplay = "true"; };
        "org.kde.kdeconnect.app" = { exec = ""; name = "KDE Connect"; settings.NoDisplay = "true"; };
      };
      qt.enable = true;
      xdg.configFile."autostart/polkit-kde-authentication-agent-1.desktop".text = ''
        [Desktop Entry]
        Hidden=true
      '';

      # XDG compliance
      xdg = {
        enable = true;
        cacheHome = "${config.home.homeDirectory}/.local/cache";
        mimeApps = {
          enable = true;
          associations.added = {
            "video/mp4" = [ "org.gnome.Totem.desktop" ];
            "video/quicktime" = [ "org.gnome.Totem.desktop" ];
            "video/webm" = [ "org.gnome.Totem.desktop" ];
            "video/x-matroska" = [ "org.gnome.Totem.desktop" ];
            "image/gif" = [ "org.gnome.Loupe.desktop" ];
            "image/png" = [ "org.gnome.Loupe.desktop" ];
            "image/jpg" = [ "org.gnome.Loupe.desktop" ];
            "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
          };
          defaultApplications = {
            "application/x-extension-htm" = "firefox"; "application/x-extension-html" = "firefox";
            "application/x-extension-shtml" = "firefox"; "application/x-extension-xht" = "firefox";
            "application/x-extension-xhtml" = "firefox"; "application/xhtml+xml" = "firefox";
            "text/html" = "firefox"; "x-scheme-handler/about" = "firefox";
            "x-scheme-handler/ftp" = "firefox"; "x-scheme-handler/http" = "firefox";
            "x-scheme-handler/https" = "firefox"; "x-scheme-handler/unknown" = "firefox";
            "x-scheme-handler/chrome" = [ "chromium-browser.desktop" ];
            "audio/*" = [ "mpv.desktop" ];
            "video/*" = [ "org.gnome.Totem.desktop" ]; "video/mp4" = [ "org.gnome.Totem.desktop" ];
            "video/x-matroska" = [ "org.gnome.Totem.desktop" ];
            "image/*" = [ "org.gnome.loupe.desktop" ]; "image/png" = [ "org.gnome.loupe.desktop" ];
            "image/jpg" = [ "org.gnome.loupe.desktop" ];
            "application/json" = [ "gnome-text-editor.desktop" ];
            "application/pdf" = "firefox";
            "application/x-gnome-saved-search" = [ "org.gnome.Nautilus.desktop" ];
            "x-scheme-handler/discord" = [ "discord.desktop" ]; "x-scheme-handler/spotify" = [ "spotify.desktop" ];
            "x-scheme-handler/tg" = [ "telegramdesktop.desktop" ];
            "application/toml" = "org.gnome.TextEditor.desktop"; "text/plain" = "org.gnome.TextEditor.desktop";
          };
        };
        userDirs = {
          enable = true; createDirectories = true;
          extraConfig.SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };

      home.sessionVariables = {
        # XDG compliance for various tools
        HISTFILE = "${config.xdg.stateHome}/bash/history";
        GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";
        NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
        NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
        NPM_CONFIG_TMP = "\${XDG_RUNTIME_DIR}/npm";
        DOCKER_CONFIG = "${config.xdg.configHome}/docker";
        ANDROID_USER_HOME = "${config.xdg.dataHome}/android";
        PSQL_HISTORY = "${config.xdg.stateHome}/psql_history";
        REDISCLI_HISTFILE = "${config.xdg.stateHome}/redis/rediscli_history";
        PARALLEL_HOME = "${config.xdg.configHome}/parallel";
        TLDR_CACHE_DIR = "${config.xdg.cacheHome}/tldr";
        XCOMPOSEFILE = "${config.xdg.configHome}/X11/xcompose";
        XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
        MOZ_ENABLE_WAYLAND = 1;
        QT_QPA_PLATFORM = "wayland;xcb";
        LIBSEAT_BACKEND = "logind";
        EDITOR = "nixCats";
        MANPAGER = "nixCats +Man!";
      };
      home.packages = with pkgs; [
        ddcutil
        mtpfs
        jmtpfs
        brightnessctl
        xdg-utils
        wl-clipboard
        clipse
        pamixer
        playerctl
        impression
        grimblast
        slurp
        sway-contrib.grimshot
        satty
      ];
    };
  };
}
