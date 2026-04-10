_: {
  den.aspects.gnome = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          gnome-tweaks
          gnomeExtensions.user-themes
          gnomeExtensions.space-bar
          gnomeExtensions.hibernate-status-button
          gnomeExtensions.appindicator
          gnomeExtensions.just-perfection
          gnomeExtensions.pano
          gnomeExtensions.search-light
          gnomeExtensions.gsconnect
          gnomeExtensions.caffeine
          gnomeExtensions.launch-new-instance
        ];

        xdg = {
          mime.enable = true;
          systemDirs.data = [
            "${pkgs.gnome-menus}/share/applications"
          ];
        };
        targets.genericLinux.enable = true;

        dconf.settings = {
          "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            binding = "<Super>Return";
            command = "ghostty";
            name = "Open Terminal";
          };
          "org/gnome/desktop/interface".enable-hot-corners = false;
          "org/gnome/desktop/thumbnailers".disable-all = false;
          "org/gnome/desktop/thumbnail-cache" = {
            maximum-age = -1;
            maximum-size = -1;
          };
          "org/gnome/shell" = {
            disable-user-extensions = false;
            enabled-extensions = [
              "user-theme@gnome-shell-extensions.gcampax.github.com"
              "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
              "space-bar@luchrioh"
              "hibernate-status@dromi"
              "appindicatorsupport@rgcjonas.gmail.com"
              "pano@elhan.io"
              "search-light@icedman.github.com"
              "gsconnect@andyholmes.github.io"
              "caffeine@patapon.info"
            ];
          };
          "org/gnome/shell/extensions/appindicator".legacy-tray-enabled = true;
          "org/gnome/desktop/wm/preferences".focus-mode = "sloppy";
          "org/gnome/desktop/wm/keybindings".close = [ "<Super>q" ];
          "org/gnome/shell/extensions/search-light".shortcut-search = [ "<Super>b" ];
        };
      };
  };
}
