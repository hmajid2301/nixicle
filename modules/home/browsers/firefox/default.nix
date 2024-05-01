{
  inputs,
  lib,
  host,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.browsers.firefox;

  extensions = with pkgs.nur.repos.rycee.firefox-addons; [
    bitwarden
    enhancer-for-youtube
    languagetool
    old-reddit-redirect
    private-relay
    return-youtube-dislikes
    reddit-enhancement-suite
    tab-stash
    stylus
    ublock-origin
    vimium
  ];

  settings = {
    "apz.overscroll.enabled" = true;
    "browser.aboutConfig.showWarning" = false;
    "browser.aboutwelcome.enabled" = false;

    "browser.uidensity" = 0;
    "gnomeTheme.activeTabContrast" = true;
    "gnomeTheme.hideSingleTab" = false;
    "gnomeTheme.hideWebrtcIndicator" = true;
    "gnomeTheme.systemIcons" = true;
    "gnomeTheme.spinner" = true;
    "layers.acceleration.force-enabled" = true;
    "identity.fxaccounts.account.device.name" = host;
    "browser.urlbar.oneOffSearches" = false;
    "browser.urlbar.suggest.engines" = false;
    "browser.uiCustomization.state" = builtins.toJSON {
      placements = {
        widget-overflow-fixed-list = [];
        unified-extensions-area = [];
        nav-bar = [
          "back-button"
          "forward-button"
          "stop-reload-button"
          "urlbar-container"
          "downloads-button"
          "fxa-toolbar-menu-button"

          # Extensions
          "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action" # Bitwarden
          "unified-extensions-button"
        ];
        toolbar-menubar = [
          "menubar-items"
        ];
        TabsToolbar = [
          "tabbrowser-tabs"
          "new-tab-button"
          "alltabs-button"
        ];
      };
      seen = [
        "save-to-pocket-button"
        "developer-button"

        # Extensions
        "_d7742d87-e61d-4b78-b8a1-b469842139fa_-browser-action" # Vimium
      ];
      dirtyAreaCache = [
        "nav-bar"
        "toolbar-menubar"
        "TabsToolbar"
        "PersonalToolbar"
        "unified-extensions-area"
      ];
      currentVersion = 20;
      newElementCount = 2;
    };
  };
  search = {
    force = true;
    default = "Kagi";
    order = ["Kagi" "Youtube" "NixOS Options" "Nix Packages" "GitHub"];

    engines = {
      "Bing".metaData.hidden = true;
      "eBay".metaData.hidden = true;
      "Wikipedia".metaData.hidden = true;
      "DuckDuckGo".metaData.hidden = true;
      "Amazon.com".metaData.hidden = true;

      "Kagi" = {
        urls = [
          {
            template = "https://kagi.com/search";
            params = [
              {
                name = "q";
                value = "{searchTerms}";
              }
            ];
          }
        ];
      };

      "YouTube" = {
        iconUpdateURL = "https://youtube.com/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = ["@yt"];
        urls = [
          {
            template = "https://www.youtube.com/results";
            params = [
              {
                name = "search_query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
      };

      "Nix Packages" = {
        icon = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";
        definedAliases = ["@np"];
        urls = [
          {
            template = "https://search.nixos.org/packages";
            params = [
              {
                name = "type";
                value = "packages";
              }
              {
                name = "query";
                value = "{searchTerms}";
              }
              {
                name = "channel";
                value = "unstable";
              }
            ];
          }
        ];
      };

      "NixOS Options" = {
        icon = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";
        definedAliases = ["@no"];
        urls = [
          {
            template = "https://search.nixos.org/options";
            params = [
              {
                name = "channel";
                value = "unstable";
              }
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
      };

      "SourceGraph" = {
        iconUpdateURL = "https://sourcegraph.com/.assets/img/sourcegraph-mark.svg";
        definedAliases = ["@sg"];

        urls = [
          {
            template = "https://sourcegraph.com/search";
            params = [
              {
                name = "q";
                value = "{searchTerms}";
              }
            ];
          }
        ];
      };

      "GitHub" = {
        iconUpdateURL = "https://github.com/favicon.ico";
        updateInterval = 24 * 60 * 60 * 1000;
        definedAliases = ["@gh"];

        urls = [
          {
            template = "https://github.com/search";
            params = [
              {
                name = "q";
                value = "{searchTerms}";
              }
            ];
          }
        ];
      };

      "Home Manager" = {
        icon = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";
        definedAliases = ["@hm"];

        url = [
          {
            template = "https://mipmip.github.io/home-manager-option-search/";
            params = [
              {
                name = "query";
                value = "{searchTerms}";
              }
            ];
          }
        ];
      };
    };
  };

  userChrome = ''
    @import "firefox-gnome-theme/userChrome.css";
  '';

  userContent = ''
    @import "firefox-gnome-theme/userContent.css;
  '';
in {
  options.browsers.firefox = {
    enable = mkEnableOption "enable firefox browser";
  };

  config = mkIf cfg.enable {
    home.file.".mozilla/firefox/default/chrome/firefox-gnome-theme".source = inputs.firefox-gnome-theme;

    xdg.mimeApps.defaultApplications = {
      "text/html" = ["firefox.desktop"];
      "text/xml" = ["firefox.desktop"];
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
    };

    programs.firefox = {
      enable = true;
      profiles.Default = {
        id = 0;
        name = "Default";
        inherit extensions settings search userChrome userContent;
        extraConfig = ''
          ${builtins.readFile "${inputs.firefox-gnome-theme}/configuration/user.js"}
        '';
      };
      profiles.work = {
        id = 1;
        name = "Work";
        inherit extensions settings search userChrome userContent;
        extraConfig = ''
          ${builtins.readFile "${inputs.firefox-gnome-theme}/configuration/user.js"}
        '';
      };
    };
  };
}
