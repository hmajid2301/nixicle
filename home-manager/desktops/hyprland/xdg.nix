{
  config,
  lib,
  ...
}: let
  browser = config.my.settings.default.browser;
in {
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
        "application/x-extension-htm" = browser;
        "application/x-extension-html" = browser;
        "application/x-extension-shtml" = browser;
        "application/x-extension-xht" = browser;
        "application/x-extension-xhtml" = browser;
        "application/xhtml+xml" = browser;
        "text/html" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/chrome" = ["chromium-browser.desktop"];
        "x-scheme-handler/ftp" = browser;
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/unknown" = browser;

        "audio/*" = ["mpv.desktop"];
        "video/*" = ["org.gnome.Totem.dekstop"];
        "video/mp4" = ["org.gnome.Totem.dekstop"];
        "image/*" = ["org.gnome.loupe.desktop"];
        "image/png" = ["org.gnome.loupe.desktop"];
        "image/jpg" = ["org.gnome.loupe.desktop"];
        "application/json" = ["gnome-text-editor.desktop"];
        "application/pdf" = browser;
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
}
