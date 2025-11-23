{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.desktops.gnome;
in
{
  # No sub-modules to import in this directory

  options.desktops.gnome = {
    enable = mkEnableOption "enable gnome DE";
  };

  config = mkIf cfg.enable {
    # services.nixicle.kdeconnect.enable = lib.mkForce false;

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

    desktops.addons = {
      gnome.enable = true;
    };

    dconf.settings = {
      "org/gnome/desktop/applications/terminal" = {
        exec = "${pkgs.ghostty}/bin/ghostty";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>Return";
        command = "ghostty";
        name = "Open Terminal";
      };

      "org/gnome/desktop/interface" = {
        enable-hot-corners = false;
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;

        enabled-extensions = [
          "user-theme@gnome-shell-extensions.gcampax.github.com"
          "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
          "space-bar@luchrioh"
          "hibernate-status@dromi"
          "appindicatorsupport@rgcjonas.gmail.com"
          "forge@jmmaranan.com"
          # "just-perfection-desktop@just-perfection"
          "pano@elhan.io"
          "search-light@icedman.github.com"
          "gsconnect@andyholmes.github.io"
          "caffeine@patapon.info"
        ];
      };

      "org/gnome/shell/extensions/appindicator" = {
        legacy-tray-enabled = true;
      };

      "org/gnome/desktop/wm/preferences" = {
        focus-mode = "sloppy";
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
      };

      "com/github/stunkymonkey/nautilus-open-any-terminal" = {
        terminal = "ghostty";
      };

      "org/gnome/shell/keybindings/toggle-application-view" = {
        "@as" = [ ];
      };

      # "org/gnome/desktop/background" = {
      #   picture-uri-dark = "file:///${pkgs.nixicle.wallpapers.Kurzgesagt-Galaxy_2}";
      # };

      "org/gnome/shell/extensions/search-light" = {
        shortcut-search = [ "<Super>b" ];
      };
    };
  };
}
