{ den, inputs, ... }:
let
  sharedNixConfig = {
    substituters = [
      # "https://attic.haseebmajid.dev/main"
      # "https://staging.attic.rs/attic-ci"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
      "https://niri.cachix.org"
    ];
    trusted-public-keys = [
      # "main:VlacPrGj7LVuEavaWpEgun9eCNvB6DPqYMe3FraKGzw="
      # "attic-ci:U5Sey4mUxwBXM3iFapmP0/ogODXywKLRNgRPQpEXxbo="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
    use-xdg-base-directories = true;
  };
in
{
  flake-file.inputs.nur.url = "github:nix-community/NUR";
  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.common = {
    includes = [
      den.aspects.stylix
      den.aspects.boot
      den.aspects.fish
    ];

    nixos =
      {
        pkgs,
        lib,
        inputs,
        ...
      }:
      {
        nixpkgs.overlays = [
          inputs.nur.overlays.default
        ];

        # Networking
        networking.firewall.enable = true;
        networking.networkmanager.enable = true;
        systemd.services.NetworkManager-wait-online.enable = false;

        # SSH
        services = {
          openssh = {
            enable = true;
            ports = [ 22 ];
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "prohibit-password";
              StreamLocalBindUnlink = "yes";
              GatewayPorts = "clientspecified";
              KexAlgorithms = [
                "sntrup761x25519-sha512@openssh.com"
                "curve25519-sha256"
                "curve25519-sha256@libssh.org"
              ];
              Ciphers = [
                "chacha20-poly1305@openssh.com"
                "aes256-gcm@openssh.com"
                "aes128-gcm@openssh.com"
              ];
              Macs = [
                "hmac-sha2-512-etm@openssh.com"
                "hmac-sha2-256-etm@openssh.com"
              ];
            };
          };
          # YubiKey
          pcscd.enable = true;
          udev = {
            packages = with pkgs; [ yubikey-personalization ];
            extraRules = ''
              ACTION=="remove",\
               ENV{ID_BUS}=="usb",\
               ENV{ID_MODEL_ID}=="0407",\
               ENV{ID_VENDOR_ID}=="1050",\
               ENV{ID_VENDOR}=="Yubico",\
               RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
            '';
          };
          dbus.packages = [ pkgs.gcr ];
          xserver.xkb = {
            layout = "gb";
            variant = "";
          };
        };

        # Sops (age key via SSH host key)
        sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

        security.pam.services = {
          swaylock.u2fAuth = true;
          hyprlock.u2fAuth = true;
          login.u2fAuth = true;
          sudo.u2fAuth = true;
        };

        # Nix settings
        nix = {
          channel.enable = false;
          nixPath = [ "nixpkgs=flake:nixpkgs" ];
          settings = {
            trusted-users = [
              "@wheel"
              "root"
            ];
            auto-optimise-store = lib.mkDefault true;
            system-features = [
              "kvm"
              "big-parallel"
              "nixos-test"
            ];
            flake-registry = "";
            require-sigs = true;
            fallback = true;
          }
          // sharedNixConfig;
          registry.nixpkgs.flake = inputs.nixpkgs;
          gc = {
            automatic = lib.mkDefault true;
            dates = lib.mkDefault "weekly";
            options = lib.mkDefault "--delete-older-than 7d";
          };
          optimise = {
            automatic = lib.mkDefault true;
            dates = lib.mkDefault [ "weekly" ];
          };
        };

        # Locale
        i18n = {
          defaultLocale = lib.mkDefault "en_GB.UTF-8";
          extraLocaleSettings = {
            LC_ADDRESS = "en_GB.UTF-8";
            LC_IDENTIFICATION = "en_GB.UTF-8";
            LC_MEASUREMENT = "en_GB.UTF-8";
            LC_MONETARY = "en_GB.UTF-8";
            LC_NAME = "en_GB.UTF-8";
            LC_NUMERIC = "en_GB.UTF-8";
            LC_PAPER = "en_GB.UTF-8";
            LC_TELEPHONE = "en_GB.UTF-8";
            LC_TIME = "en_GB.UTF-8";
          };
        };
        time.timeZone = "Europe/London";
        console.keyMap = "uk";

        security.sudo.extraConfig = ''
          Defaults secure_path="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"
        '';
      };

    homeManager =
      {
        pkgs,
        config,
        ...
      }:
      {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];
        home.sessionVariables.NH_SEARCH_CHANNEL = "nixos-unstable";

        # Sops (HM)
        sops = {
          age = {
            generateKey = true;
            keyFile = "/home/${config.home.username}/.config/sops/age/keys.txt";
            sshKeyPaths = [ "/home/${config.home.username}/.ssh/id_ed25519" ];
          };
          defaultSymlinkPath = "/run/user/1000/secrets";
          defaultSecretsMountPoint = "/run/user/1000/secrets.d";
        };

        # Firefox
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
        programs = {
          firefox = {
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
                # "identity.fxaccounts.account.device.name" = "${config.home.username}@(hostname)";
                "browser.urlbar.oneOffSearches" = false;
                # "browser.search.hiddenOneOffs" = "Google,Yahoo,Bing,Amazon.com,Twitter,Wikipedia (en),YouTube,eBay";
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
                  # "Home Manager"
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
                  # "Google".metaData.hidden = true;
                  # "Yahoo".metaData.hidden = true;
                  # "Bing".metaData.hidden = true;
                  # "DuckDuckGo".metaData.hidden = true;
                  # "Amazon.com".metaData.hidden = true;
                  # "Wikipedia (en)".metaData.hidden = true;
                  # "YouTube".metaData.hidden = true;
                  # "eBay".metaData.hidden = true;
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
          carapace.enable = true;
          foot = {
            enable = true;
            settings = {
              main = {
                shell = "fish";
                pad = "15x15";
                selection-target = "clipboard";
              };
              scrollback.lines = 10000;
            };
          };
          ghostty = {
            enable = true;
            enableFishIntegration = true;
            settings = {
              command = "fish";
              gtk-titlebar = false;
              gtk-tabs-location = "hidden";
              gtk-single-instance = true;
              window-padding-x = 6;
              window-padding-y = 6;
              copy-on-select = "clipboard";
              cursor-style = "block";
              confirm-close-surface = false;
              keybind = [
                "ctrl+shift+plus=increase_font_size:1"
                "ctrl+shift+minus=decrease_font_size:1"
                "ctrl+shift+0=reset_font_size"
                "shift+enter=text:\\u001b[13;2u"
              ];
            };
          };
          zk = {
            enable = true;
            settings = {
              note = {
                language = "en";
                default-title = "Untitled";
                filename = "{{id}}-{{slug title}}";
                extension = "md";
                template = "default.md";
                id-charset = "alphanum";
                id-length = 8;
                id-case = "lower";
              };
              format.markdown = {
                hashtags = true;
                colon-tags = true;
                multiword-tags = false;
              };
              tool = {
                editor = "nvim";
                pager = "less -FIRX";
                fzf-preview = "bat -p --color always {-1}";
              };
              lsp.diagnostics = {
                wiki-title = "hint";
                dead-link = "error";
              };
              alias = {
                ls = "zk list $@";
                ed = "zk edit $@";
                n = "zk new $@";
              };
            };
          };
          k9s.enable = true;
        };

        home.packages = with pkgs; [
          keymapp

          # k8s tools
          kubectl
          kubectx
          kubelogin
          kubelogin-oidc
          stern
          kubernetes-helm
          kustomize
          fluxcd
          kubefwd

          # GUI apps
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
