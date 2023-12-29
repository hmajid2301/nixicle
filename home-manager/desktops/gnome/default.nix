{
  lib,
  pkgs,
  config,
  ...
}:
with lib.hm.gvariant; {
  home.file.".themes" = {
    source = ./themes;
    recursive = true;
  };

  # To show nix installed apps in Gnome
  targets.genericLinux.enable = true;
  xdg.mime.enable = true;
  xdg.systemDirs.data = ["${config.home.homeDirectory}/.nix-profile/share/applications"];

  home.packages = with pkgs; [
    # apps
    gnome.gnome-tweaks
    gnome.dconf-editor
    gnome-extension-manager
    gradience

    # useful utils
    nautilus-open-any-terminal

    # extensions
    gnomeExtensions.appindicator
    gnomeExtensions.aylurs-widgets
    gnomeExtensions.blur-my-shell
    gnomeExtensions.extensions-sync
    gnomeExtensions.hibernate-status-button
    gnomeExtensions.logo-menu
    gnomeExtensions.just-perfection
    gnomeExtensions.pano
    gnomeExtensions.pop-shell
    gnomeExtensions.rounded-window-corners
    gnomeExtensions.search-light
    gnomeExtensions.smart-auto-move
    gnomeExtensions.space-bar
    gnomeExtensions.order-gnome-shell-extensions

    libgda # used by pano extension

    # styles
    adw-gtk3
    adwaita-qt
    papirus-icon-theme
    papirus-folders
  ];

  dconf.settings = {
    "org/gnome/desktop/applications/terminal" = {
      exec = "${pkgs.foot}/bin/foot";
    };

    "ca/desrt/dconf-editor" = {
      saved-pathbar-path = "/org/gnome/shell/extensions/pop-shell/";
      saved-view = "/org/gnome/shell/extensions/pop-shell/";
      show-warning = false;
      window-height = 1375;
      window-is-maximized = false;
      window-width = 2240;
    };

    "org/gnome/desktop/interface" = {
      clock-show-seconds = true;
      clock-show-weekday = true;
      color-scheme = "prefer-dark";
      cursor-size = 32;
      cursor-theme = "Adwaita";
      enable-animations = true;
      enable-hot-corners = false;
      font-antialiasing = "grayscale";
      font-hinting = "slight";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      monospace-font-name = config.my.settings.fonts.monospace;
      show-battery-percentage = true;
      toolkit-accessibility = false;
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super><cr>";
      command = "foot";
      name = "Open Terminal";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      binding = "<Control><Alt>Delete";
      command = "systemctl hibernate";
      name = "Hibernate";
    };

    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "hibernate";
    };

    "org/gnome/shell/extensions/Logo-menu" = {
      hide-forcequit = true;
      hide-softwarecentre = true;
      menu-button-extensions-app = "com.mattjakeman.ExtensionManager.desktop";
      menu-button-icon-image = 23;
      menu-button-terminal = "alacritty";
      show-power-options = true;
    };

    "org/gnome/shell/extensions/appindicator" = {
      custom-icons = "@a(sss) []";
      legacy-tray-enabled = true;
    };

    "org/gnome/shell/extensions/aylurs-widgets" = {
      background-clock = true;
      background-clock-bg-color = "rgba(0,0,0,0)";
      background-clock-clock-custom-font = true;
      background-clock-clock-font = "Product Sans";
      background-clock-clock-shadow-x = 1;
      background-clock-clock-size = 80;
      background-clock-date-color = "rgb(242,242,242)";
      background-clock-date-custom-font = false;
      background-clock-date-shadow-blur = 4;
      background-clock-date-size = 38;
      background-clock-enable-date = true;
      background-clock-position = 1;
      background-clock-x-offset = 80;
      background-clock-y-offset = 80;
      battery-bar = false;
      battery-bar-bg-color = "rgb(24,24,37)";
      battery-bar-charging-color = "rgb(166,227,161)";
      battery-bar-color = "rgb(180,190,254)";
      battery-bar-font-bg-color = "rgb(205,214,244)";
      battery-bar-font-color = "rgb(17,17,27)";
      battery-bar-height = 24;
      battery-bar-icon-position = 0;
      battery-bar-low-color = "rgb(243,139,168)";
      battery-bar-low-threshold = 0;
      battery-bar-offset = 3;
      battery-bar-padding-left = 3;
      battery-bar-padding-right = 3;
      battery-bar-position = 2;
      battery-bar-roundness = 7;
      battery-bar-show-icon = false;
      battery-bar-show-percentage = true;
      battery-bar-width = 70;
      dash-app-icon-size = 44;
      dash-apps-cols = 3;
      dash-apps-icon-size = 34;
      dash-apps-rows = 3;
      dash-apps-x-expand = false;
      dash-board = false;
      dash-board-darken = true;
      dash-board-x-align = 2;
      dash-board-x-offset = 0;
      dash-board-y-align = 2;
      dash-board-y-offset = 0;
      dash-button-enable = false;
      dash-button-icon-hide = true;
      dash-button-label = "Dash";
      dash-button-position = 0;
      dash-button-show-icon = false;
      dash-clock-background = false;
      dash-clock-vertical = false;
      dash-clock-width = 200;
      dash-clock-x-align = 0;
      dash-clock-x-expand = true;
      dash-clock-y-align = 0;
      dash-clock-y-expand = false;
      dash-hide-activities = false;
      dash-layout = 0;
      dash-layout-json = ''
        {"children":[{"vertical":false,"x_align":"FILL","x_expand":true,"children":["clock","settings","system"]},{"vertical":false,"children":[{"vertical":true,"children":["media","links"]},"apps"]},{"vertical":false,"children":["user","levels"]}],"vertical":true}
      '';
      dash-levels-background = true;
      dash-levels-show-temp = true;
      dash-levels-vertical = false;
      dash-levels-width = 0;
      dash-levels-x-align = 0;
      dash-levels-x-expand = true;
      dash-link-names = ["reddit" "youtube" "gmail" "twitter" "github"];
      dash-link-urls = ["https://www.reddit.com/" "https://www.youtube.com/" "https://www.gmail.com/" "https://twitter.com/" "https://www.github.com/"];
      dash-links-background = true;
      dash-links-icon-size = 58;
      dash-links-names = ["reddit" "youtube" "gmail" "github"];
      dash-links-urls = ["https://www.reddit.com/" "https://www.youtube.com/" "https://www.gmail.com/" "https://www.github.com/"];
      dash-links-vertical = false;
      dash-links-x-expand = false;
      dash-links-y-expand = false;
      dash-media-cover-height = 200;
      dash-media-cover-width = 200;
      dash-media-prefer = "Amberol";
      dash-media-style = 1;
      dash-read-config = 9;
      dash-settings-icon-size = 34;
      dash-settings-vertical = false;
      dash-shortcut = [""];
      dash-system-background = true;
      dash-system-icon-size = 34;
      dash-system-layout = 0;
      dash-user-background = false;
      dash-user-icon-roundness = 99;
      dash-user-icon-width = 100;
      dash-user-vertical = true;
      dash-user-x-align = 2;
      dash-user-x-expand = false;
      dash-user-y-align = 2;
      dash-user-y-expand = false;
      date-menu-custom-menu = true;
      date-menu-hide-notifications = true;
      date-menu-hide-stock-mpris = false;
      date-menu-indicator-position = 0;
      date-menu-levels-show-battery = false;
      date-menu-levels-show-cpu = false;
      date-menu-levels-show-ram = false;
      date-menu-media-prefer = "Amberol";
      date-menu-media-show-text = true;
      date-menu-media-text-position = 1;
      date-menu-mirror = false;
      date-menu-mod = false;
      date-menu-offset = 1;
      date-menu-position = 1;
      date-menu-remove-padding = false;
      date-menu-show-clocks = false;
      date-menu-show-events = false;
      date-menu-show-media = false;
      date-menu-show-system-levels = false;
      date-menu-show-user = false;
      date-menu-show-weather = false;
      date-menu-tweaks = true;
      dynamic-panel = false;
      dynamic-panel-floating-style = false;
      dynamic-panel-useless-gaps = 0;
      media-player = true;
      media-player-colored-player-icon = true;
      media-player-controls-offset = 9;
      media-player-controls-position = 1;
      media-player-cover-height = 100;
      media-player-cover-roundness = 15;
      media-player-cover-width = 98;
      media-player-enable-controls = true;
      media-player-enable-track = true;
      media-player-max-width = 300;
      media-player-offset = 3;
      media-player-player-icon-position = 0;
      media-player-position = 1;
      media-player-prefer = "Spotify";
      media-player-show-loop-shuffle = true;
      media-player-show-player-icon = true;
      media-player-show-text = true;
      media-player-show-volume = true;
      media-player-style = 1;
      media-player-text-align = 1;
      media-player-text-position = 0;
      notification-indicator = true;
      notification-indicator-hide-counter = false;
      notification-indicator-hide-on-zero = true;
      notification-indicator-offset = 0;
      notification-indicator-position = 3;
      notification-indicator-show-dnd = false;
      power-menu = false;
      power-menu-dialog-padding = 34;
      power-menu-dialog-roundness = 20;
      power-menu-label-position = 1;
      power-menu-layout = 1;
      quick-settings-adjust-roundness = false;
      quick-settings-levels-show-battery = false;
      quick-settings-levels-show-cpu = false;
      quick-settings-levels-show-ram = false;
      quick-settings-levels-show-storage = true;
      quick-settings-levels-show-temp = true;
      quick-settings-media-cover-height = 60;
      quick-settings-media-cover-roundness = 5;
      quick-settings-media-cover-width = 60;
      quick-settings-media-prefer = "Amberol";
      quick-settings-media-prefer-one = true;
      quick-settings-media-show-loop-shuffle = false;
      quick-settings-media-show-volume = false;
      quick-settings-media-style = 1;
      quick-settings-menu-width = 405;
      quick-settings-show-airplane = false;
      quick-settings-show-media = false;
      quick-settings-show-network-bt = false;
      quick-settings-show-notifications = true;
      quick-settings-show-system-levels = false;
      quick-settings-show-wired = true;
      quick-settings-style = 3;
      quick-settings-tweaks = true;
      window-headerbar = true;
      workspace-indicator = false;
      workspace-indicator-offset = 2;
      workspace-indicator-show-names = false;
      workspace-indicator-style = 0;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur-on-overview = true;
    };

    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      style-components = 2;
    };

    "org/gnome/shell/extensions/just-perfection" = {
      accessibility-menu = true;
      activities-button-icon-monochrome = true;
      app-menu = true;
      app-menu-icon = true;
      background-menu = true;
      calendar = true;
      clock-menu = true;
      dash = true;
      dash-icon-size = 0;
      double-super-to-appgrid = true;
      events-button = true;
      gesture = true;
      hot-corner = false;
      osd = true;
      panel = true;
      panel-arrow = true;
      panel-corner-size = 0;
      panel-in-overview = true;
      panel-notification-icon = false;
      power-icon = true;
      ripple-box = true;
      search = true;
      show-apps-button = true;
      startup-status = 1;
      theme = false;
      weather = true;
      window-demands-attention-focus = false;
      window-picker-icon = true;
      window-preview-caption = true;
      workspace = true;
      workspace-background-corner-size = 0;
      workspace-popup = true;
      workspaces-in-app-grid = true;
    };

    "org/gnome/shell/extensions/pano" = {
      is-in-incognito = false;
      send-notification-on-copy = false;
      sync-primary = false;
    };

    "org/gnome/shell/extensions/pop-shell" = {
      activate-launcher = ["<Super>space"];
      active-hint = true;
      active-hint-border-radius = mkUint32 15;
      gap-inner = mkUint32 3;
      gap-outer = mkUint32 3;
      hint-color-rgba = "rgb(186, 187, 241)";
      show-skip-taskbar = true;
      smart-gaps = false;
      snap-to-grid = true;
      tile-by-default = true;
      toggle-stacking-global = [];
    };

    "org/gnome/shell/extensions/rounded-window-corners" = {
      border-color = mkTuple [0.729411780834198 0.7607843279838562];
      border-width = 0;
      custom-rounded-corner-settings = "@a{sv} {}";
      focused-shadow = "{'vertical_offset': 4, 'horizontal_offset': 0, 'blur_offset': 28, 'spread_radius': 4, 'opacity': 60}";
      global-rounded-corner-settings = "{'padding': <{'left': <uint32 1>, 'right': <uint32 1>, 'top': <uint32 1>, 'bottom': <uint32 1>}>, 'keep_rounded_corners': <{'maximized': <false>, 'fullscreen': <false>}>, 'border_radius': <uint32 12>, 'smoothing': <0.10000000000000001>, 'enabled': <true>}";
      settings-version = mkUint32 5;
      skip-libadwaita-app = false;
      tweak-kitty-terminal = false;
      unfocused-shadow = "{'vertical_offset': 2, 'horizontal_offset': 0, 'blur_offset': 12, 'spread_radius': -1, 'opacity': 65}";
    };

    "org/gnome/shell/extensions/search-light" = {
      background-color = mkTuple [0.1568627506494522 0.16470588743686676];
      blur-background = true;
      blur-brightness = 0.6;
      blur-sigma = 200.0;
      border-radius = 3.0;
      entry-font-size = 1;
      monitor-count = 1;
      popup-at-cursor-monitor = true;
      scale-height = 0.1;
      scale-width = 0.1;
      shortcut-search = ["<Super>a"];
      show-panel-icon = true;
    };

    "org/gnome/shell/extensions/space-bar/behavior" = {
      smart-workspace-names = false;
    };

    "org/gnome/shell/extensions/space-bar/shortcuts" = {
      enable-move-to-workspace-shortcuts = true;
    };
  };
}
