{
  lib,
  config,
  pkgs,
  host,
  ...
}:
with lib;
let
  cfg = config.browsers.firefox;
in
{
  options.browsers.firefox = {
    enable = mkEnableOption "enable firefox browser";
  };

  config = mkIf cfg.enable {
    xdg.mimeApps.defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "text/xml" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
    };

    programs.firefox = {
      enable = true;
      profiles.default = {
        name = "Default";

        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          bitwarden
          enhancer-for-youtube
          linkwarden
          languagetool
          old-reddit-redirect
          private-relay
          reddit-enhancement-suite
          tab-stash
          stylus
          ublock-origin
          vimium
        ];

        settings = {
          "browser.uidensity" = 0;
          "gnomeTheme.activeTabContrast" = true;
          "gnomeTheme.hideSingleTab" = false;
          "gnomeTheme.hideWebrtcIndicator" = true;
          "gnomeTheme.systemIcons" = true;
          "gnomeTheme.spinner" = true;
          "layers.acceleration.force-enabled" = true;
          "identity.fxaccounts.account.device.name" = "${config.nixicle.user.name}@${host}";
          "browser.urlbar.oneOffSearches" = false;
          "browser.search.hiddenOneOffs" = "Google,Yahoo,Bing,Amazon.com,Twitter,Wikipedia (en),YouTube,eBay";
          "extensions.pocket.enabled" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.openpage" = false;
          "browser.urlbar.suggest.bookmark" = false;
          "browser.urlbar.suggest.addons" = false;
          "browser.urlbar.suggest.pocket" = false;
          "browser.urlbar.suggest.topsites" = false;
        };
        search = {
          force = true;
          default = "Kagi";
          order = [
            "Kagi"
            "NixOS Options"
            "Nix Packages"
            "GitHub"
            "HackerNews"
          ];

          # "Bing".metaData.hidden = true;
          # "eBay".metaData.hidden = true;
          # "DuckDuckGo".metaData.hidden = true;
          # "Amazon.com".metaData.hidden = true;
          # "Wikipedia (en)".metaData.hidden = true;
          # "YouTube".metaata.hidden = true;
          # "Kagi".metaData.hidden = true;
          # "Nix Packages".metaData.hidden = true;
          # "NixOS Options".metaData.hidden = true;
          # "Home Manager".metaData.hidden = true;
          # "SourceGraph".metaData.hidden = true;
          # "GitHub".metaData.hidden = true;

          engines = {
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

            "Nix Packages" = {
              icon = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";
              definedAliases = [ "@np" ];
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
              definedAliases = [ "@no" ];
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
              definedAliases = [ "@sg" ];

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
              definedAliases = [ "@gh" ];

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
              icon = "https://home-manager-options.extranix.com/images/home-manager-option-search2.png";
              definedAliases = [ "@hm" ];

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
      };
    };
  };
}
