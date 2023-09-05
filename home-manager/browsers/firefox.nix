{ inputs, ... }: {
  # Add Firefox GNOME theme directory
  home.file."firefox-gnome-theme" = {
    target = ".mozilla/firefox/default/chrome/firefox-gnome-theme";
    source = fetchTarball {
      url = "https://github.com/rafaelmardojai/firefox-gnome-theme/archive/refs/tags/v113.zip";
      sha256 = "sha256:0vxyi5vv6qzgzfh5y83spxig7f8hkhdkr29i957q28qmjmwx6m3k";
    };
  };

  # home = {
  #   persistence = {
  #     # Not persisting is safer
  #     "/persist/home/misterio".directories = [ ".mozilla/firefox" ];
  #   };
  # };

  programs.firefox = {
    enable = true;
    profiles.default = {
      name = "Default";
      settings = {
        "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";

        # For Firefox GNOME theme:
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.tabs.drawInTitlebar" = true;
        "svg.context-properties.content.enabled" = true;
      };
      userChrome = ''
        @import "firefox-gnome-theme/userChrome.css";
        @import "firefox-gnome-theme/theme/colors/dark.css";
      '';
    };
    #extensions = nur.repos.rycee.firefox-addons; [
    #  bitwarden
    #  facebook-container
    #  duckduckgo-privacy-essentials
    #  reddit-enhancement-suite
    #  tridactyl
    #  private-relay
    #  privacy-badger
    #  return-youtube-dislike
    #  stylus
    #  ublock-origin
    #];
  };
}
