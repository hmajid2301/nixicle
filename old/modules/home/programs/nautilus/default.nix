{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.nautilus;
in
{
  options.programs.nautilus = {
    enable = mkEnableOption "enable nautilus file manager configuration";
  };

  config = mkIf cfg.enable {
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
    };

    gtk.gtk3.bookmarks = [
      "file://${config.home.homeDirectory}/Downloads"
    ];

    dconf.settings = {
      "org/gnome/nautilus/preferences" = {
        show-image-thumbnails = "always";
        thumbnail-limit = 10;
        show-directory-item-counts = "never";
        executable-text-activation = "ask";
        always-use-location-entry = false;
        default-folder-viewer = "icon-view";
        thumbnail-cache-time = 30;
        show-recent = false;
      };

      "org/gnome/nautilus/icon-view" = {
        captions = [
          "none"
          "none"
          "none"
        ];
      };

      "org/gnome/nautilus/list-view" = {
        use-tree-view = false;
      };

      "org/gnome/desktop/privacy" = {
        remember-recent-files = false;
      };

      "com/github/stunkymonkey/nautilus-open-any-terminal" = {
        terminal = "ghostty";
        flatpak = "off";
        keybindings = "<Ctrl><Alt>t";
        new-tab = false;
      };
    };
  };
}
