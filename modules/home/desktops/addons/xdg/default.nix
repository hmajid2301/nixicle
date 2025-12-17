{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.addons.xdg;
in
{
  options.desktops.addons.xdg = with types; {
    enable = mkBoolOpt false "manage xdg config";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      # XDG compliance for various tools
      HISTFILE = lib.mkForce "${config.xdg.stateHome}/bash/history";
      GTK2_RC_FILES = lib.mkForce "${config.xdg.configHome}/gtk-2.0/gtkrc";

      # Node.js
      NODE_REPL_HISTORY = "${config.xdg.stateHome}/node_repl_history";

      # npm
      NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
      NPM_CONFIG_CACHE = "${config.xdg.cacheHome}/npm";
      NPM_CONFIG_TMP = "\${XDG_RUNTIME_DIR}/npm";

      # Docker
      DOCKER_CONFIG = "${config.xdg.configHome}/docker";

      # Android
      ANDROID_USER_HOME = "${config.xdg.dataHome}/android";

      # PostgreSQL
      PSQL_HISTORY = "${config.xdg.stateHome}/psql_history";

      # Redis
      REDISCLI_HISTFILE = "${config.xdg.stateHome}/redis/rediscli_history";

      # Parallel
      PARALLEL_HOME = "${config.xdg.configHome}/parallel";

      # TLDR cache
      TLDR_CACHE_DIR = "${config.xdg.cacheHome}/tldr";

      # X resources
      XCOMPOSEFILE = "${config.xdg.configHome}/X11/xcompose";
      XCOMPOSECACHE = "${config.xdg.cacheHome}/X11/xcompose";
    };

    xdg = {
      enable = true;
      cacheHome = config.home.homeDirectory + "/.local/cache";

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
          "application/x-extension-htm" = "firefox";
          "application/x-extension-html" = "firefox";
          "application/x-extension-shtml" = "firefox";
          "application/x-extension-xht" = "firefox";
          "application/x-extension-xhtml" = "firefox";
          "application/xhtml+xml" = "firefox";
          "text/html" = "firefox";
          "x-scheme-handler/about" = "firefox";
          "x-scheme-handler/chrome" = [ "chromium-browser.desktop" ];
          "x-scheme-handler/ftp" = "firefox";
          "x-scheme-handler/http" = "firefox";
          "x-scheme-handler/https" = "firefox";
          "x-scheme-handler/unknown" = "firefox";

          "audio/*" = [ "mpv.desktop" ];
          "video/*" = [ "org.gnome.Totem.desktop" ];
          "video/mp4" = [ "org.gnome.Totem.desktop" ];
          "video/x-matroska" = [ "org.gnome.Totem.desktop" ];
          "image/*" = [ "org.gnome.loupe.desktop" ];
          "image/png" = [ "org.gnome.loupe.desktop" ];
          "image/jpg" = [ "org.gnome.loupe.desktop" ];
          "application/json" = [ "gnome-text-editor.desktop" ];
          "application/pdf" = "firefox";
          "application/x-gnome-saved-search" = [ "org.gnome.Nautilus.desktop" ];
          "x-scheme-handler/discord" = [ "discord.desktop" ];
          "x-scheme-handler/spotify" = [ "spotify.desktop" ];
          "x-scheme-handler/tg" = [ "telegramdesktop.desktop" ];
          "application/toml" = "org.gnome.TextEditor.desktop";
          "text/plain" = "org.gnome.TextEditor.desktop";
        };
      };

      userDirs = {
        enable = true;
        createDirectories = true;
        extraConfig = {
          XDG_SCREENSHOTS_DIR = "${config.xdg.userDirs.pictures}/Screenshots";
        };
      };
    };
  };
}
