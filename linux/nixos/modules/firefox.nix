
{
  # Add Firefox GNOME theme directory
  home.file."firefox-gnome-theme" = {
    target = ".mozilla/firefox/default/chrome/firefox-gnome-theme";
    source = (fetchTarball {
      url = "https://github.com/rafaelmardojai/firefox-gnome-theme/archive/master.tar.gz";
      sha256="sha256:04flxjwb8knakjqpnkh9hib8x15zh9hv2snjfz1h59ydiyjpkzq1";
    });
  };

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
  };
}
