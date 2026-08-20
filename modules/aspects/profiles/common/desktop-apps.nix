{ ... }:
{
  den.aspects.commonDesktopApps = {
    homeManager =
      { pkgs, config, ... }:
      {
        xdg = {
          mimeApps.defaultApplications = {
            "text/html" = [ "firefox.desktop" ];
            "text/xml" = [ "firefox.desktop" ];
            "x-scheme-handler/http" = [ "firefox.desktop" ];
            "x-scheme-handler/https" = [ "firefox.desktop" ];
          };
          systemDirs.data = [
            "${pkgs.nautilus}/share/gsettings-schemas/${pkgs.nautilus.name}"
          ];
          userDirs = {
            enable = true;
            createDirectories = true;
            setSessionVariables = false;
          };
        };

        programs.firefox = {
          enable = true;
          configPath = "${config.xdg.configHome}/mozilla/firefox";
          package = pkgs.firefox-bin;
          profiles.default = {
            name = "Default";
            settings = {
              "browser.uidensity" = 0;
              "gnomeTheme.activeTabContrast" = true;
              "gnomeTheme.hideSingleTab" = false;
              "gnomeTheme.hideWebrtcIndicator" = true;
              "gnomeTheme.systemIcons" = true;
              "gnomeTheme.spinner" = true;
              "layers.acceleration.force-enabled" = true;
              "browser.urlbar.oneOffSearches" = false;
              "browser.urlbar.shortcuts.bookmarks" = false;
              "browser.urlbar.shortcuts.history" = false;
              "browser.urlbar.shortcuts.tabs" = false;
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
                  metaData.hideOneOffButton = true;
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
                  metaData.hideOneOffButton = true;
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
                  metaData.hideOneOffButton = true;
                };
                "GitHub" = {
                  icon = "https://github.com/favicon.ico";
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
                  metaData.hideOneOffButton = true;
                };
                "Home Manager" = {
                  icon = "https://home-manager-options.extranix.com/images/home-manager-option-search2.png";
                  definedAliases = [ "@hm" ];
                  urls = [
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
                  metaData.hideOneOffButton = true;
                };
                "HackerNews" = {
                  icon = "https://news.ycombinator.com/favicon.ico";
                  definedAliases = [ "@hn" ];
                  urls = [
                    {
                      template = "https://hn.algolia.com/";
                      params = [
                        {
                          name = "q";
                          value = "{searchTerms}";
                        }
                      ];
                    }
                  ];
                  metaData.hideOneOffButton = true;
                };
              };
            };
          };
        };

        home.packages = with pkgs; [
          keymapp
          trayscale
          foliate
          pwvucontrol
          sushi
          gnome-disk-utility
          totem
          gvfs
          loupe
          nautilus
          ffmpegthumbnailer
          nautilus-python
          gst_all_1.gst-libav
        ];

        gtk.gtk3.bookmarks = [ "file://${config.home.homeDirectory}/Downloads" ];

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
          "org/gnome/nautilus/icon-view".captions = [
            "none"
            "none"
            "none"
          ];
          "org/gnome/nautilus/list-view".use-tree-view = false;
          "org/gnome/desktop/privacy".remember-recent-files = false;
          "com/github/stunkymonkey/nautilus-open-any-terminal" = {
            terminal = "ghostty";
            flatpak = "off";
            keybindings = "<Ctrl><Alt>t";
            new-tab = false;
          };
        };
      };
  };
}
