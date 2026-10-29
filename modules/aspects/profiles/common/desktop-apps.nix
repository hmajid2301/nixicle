{ den, lib, ... }:
{
  den.aspects.commonDesktopApps = {
    includes = [
      (den.batteries.unfree [
        "keymapp"
        "firefox-bin"
        "firefox-bin-unwrapped"
      ])
    ];

    homeManager =
      { pkgs, config, ... }:
      let
        colors = config.lib.stylix.colors.withHashtag;
        # Catppuccin latte equivalents for light-scheme pages
        latte = {
          base00 = "#eff1f5";
          base01 = "#e6e9ef";
          base05 = "#4c4f69";
          base07 = "#7287fd";
        };
      in
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
              "widget.disable-native-themes" = true;
            };
            userChrome = lib.mkAfter (
              lib.concatStringsSep "\n" [
                "  :root {"
                "    --gnome-menu-color: ${colors.base05} !important;"
                "    --gnome-selected-color: color-mix(in srgb, ${colors.base07} 40%, transparent) !important;"
                "    --gnome-selected-hover-color: color-mix(in srgb, ${colors.base07} 50%, transparent) !important;"
                "  }"
                ""
                "  menupopup > menuitem[_moz-menuactive]:not([disabled=\"true\"]),"
                "  menupopup > menu[_moz-menuactive]:not([disabled=\"true\"]) {"
                "    color: ${colors.base00} !important;"
                "    background-color: ${colors.base07} !important;"
                "  }"
              ]
            );
            # No background on the closed select: unstyled selects keep the
            # page/OS box so we don't force a palette that clashes, and sites
            # styling their own selects win. Theme only the native dropdown
            # option list for readability.
            userContent = lib.mkAfter (
              lib.concatStringsSep "\n" [
                "  select {"
                "    color: light-dark(${latte.base05}, ${colors.base05});"
                "  }"
                ""
                "  select option, select optgroup {"
                "    color: light-dark(${latte.base05}, ${colors.base05});"
                "    background-color: light-dark(${latte.base01}, ${colors.base01});"
                "  }"
                ""
                "  select option:checked,"
                "  select option:hover {"
                "    color: light-dark(${latte.base00}, ${colors.base00});"
                "    background-color: light-dark(${latte.base07}, ${colors.base07});"
                "  }"
              ]
            );
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
