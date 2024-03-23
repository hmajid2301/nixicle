{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.desktops.addons.xdg;
in {
  options.desktops.addons.xdg = with types; {
    enable = mkBoolOpt false "manage xdg config";
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      HISTFILE = lib.mkForce "${config.xdg.stateHome}/bash/history";
      #GNUPGHOME = lib.mkForce "${config.xdg.dataHome}/gnupg";
      GTK2_RC_FILES = lib.mkForce "${config.xdg.configHome}/gtk-2.0/gtkrc";
    };

    xdg = {
      enable = true;
      cacheHome = config.home.homeDirectory + "/.local/cache";

      mimeApps = {
        enable = true;
        associations.added = {
          "video/mp4" = ["org.gnome.Totem.desktop"];
          "video/quicktime" = ["org.gnome.Totem.desktop"];
          "video/webm" = ["org.gnome.Totem.desktop"];
          "image/png" = ["org.gnome.Loupe.desktop"];
          "image/jpg" = ["org.gnome.Loupe.desktop"];
          "image/jpeg" = ["org.gnome.Loupe.desktop"];
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
          "x-scheme-handler/chrome" = ["chromium-browser.desktop"];
          "x-scheme-handler/ftp" = "firefox";
          "x-scheme-handler/http" = "firefox";
          "x-scheme-handler/https" = "firefox";
          "x-scheme-handler/unknown" = "firefox";

          "audio/*" = ["mpv.desktop"];
          "video/*" = ["org.gnome.Totem.dekstop"];
          "video/mp4" = ["org.gnome.Totem.dekstop"];
          "image/*" = ["org.gnome.loupe.desktop"];
          "image/png" = ["org.gnome.loupe.desktop"];
          "image/jpg" = ["org.gnome.loupe.desktop"];
          "application/json" = ["gnome-text-editor.desktop"];
          "application/pdf" = "firefox";
          "application/x-gnome-saved-search" = ["org.gnome.Nautilus.desktop"];
          "x-scheme-handler/discord" = ["discord.desktop"];
          "x-scheme-handler/spotify" = ["spotify.desktop"];
          "x-scheme-handler/tg" = ["telegramdesktop.desktop"];
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
