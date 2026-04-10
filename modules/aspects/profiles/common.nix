{ den, inputs, ... }:
let
  sharedNixConfig = {
    substituters = [
      # "https://attic.haseebmajid.dev/main"
      "https://staging.attic.rs/attic-ci"
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
      "https://niri.cachix.org"
    ];
    trusted-public-keys = [
      # "main:VlacPrGj7LVuEavaWpEgun9eCNvB6DPqYMe3FraKGzw="
      "attic-ci:U5Sey4mUxwBXM3iFapmP0/ogODXywKLRNgRPQpEXxbo="
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
  fishPlugins = pkgs: [
    {
      name = "bass";
      inherit (pkgs.fishPlugins.bass) src;
    }
    {
      name = "fzf-fish";
      inherit (pkgs.fishPlugins.fzf-fish) src;
    }
    {
      name = "fifc";
      inherit (pkgs.fishPlugins.fifc) src;
    }
    {
      name = "nvm.fish";
      src = pkgs.fetchFromGitHub {
        owner = "jorgebucaran";
        repo = "nvm.fish";
        rev = "846f1f20b2d1d0a99e344f250493c41a450f9448";
        sha256 = "sha256-u3qhoYBDZ0zBHbD+arDxLMM8XoLQlNI+S84wnM3nDzg=";
      };
    }
    {
      name = "git-abbr";
      inherit (pkgs.fishPlugins.git-abbr) src;
    }
    {
      name = "completion-sync";
      src = pkgs.fetchFromGitHub {
        owner = "iynaix";
        repo = "fish-completion-sync";
        rev = "4f058ad2986727a5f510e757bc82cbbfca4596f0";
        sha256 = "sha256-kHpdCQdYcpvi9EFM/uZXv93mZqlk1zCi2DRhWaDyK5g=";
      };
    }
    {
      name = "hm-generation-reload";
      src = pkgs.writeTextDir "conf.d/hm-generation-reload.fish" ''
        function __hm_generation_reload --on-event fish_prompt
          set -l hm_gen_file ~/.local/state/home-manager/gcroots/current-home
          if test -L $hm_gen_file
            set -l current_gen (readlink $hm_gen_file)
            if set -q __hm_last_generation; and test "$__hm_last_generation" != "$current_gen"
              echo "🔄 Home Manager generation changed, reloading fish..."
              set -e __hm_last_generation
              exec fish
            end
            set -g __hm_last_generation $current_gen
          end
        end
      '';
    }
  ];
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
        networking.networkmanager = {
          enable = true;
          settings.main.no-auto-default = "*";
        };
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
                "identity.fxaccounts.account.device.name" = "${config.home.username}@(hostname)";
                "browser.urlbar.oneOffSearches" = false;
                "browser.search.hiddenOneOffs" = "Google,Yahoo,Bing,Amazon.com,Twitter,Wikipedia (en),YouTube,eBay";
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
          carapace.enable = true;
          fish = {
            enable = true;
            interactiveShellInit = ''
              ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source
              set -x GOPATH $XDG_DATA_HOME/go
              set -x GOPRIVATE "github.com/NalaMoney"
              set -gx PATH /usr/local/bin /usr/bin ~/.local/bin $GOPATH/bin/ $PATH

              # fifc setup
              set -Ux fifc_editor nvim
              set -U fifc_keybinding \cx
              bind \cx _fifc
              bind -M insert \cx _fifc

              fzf_configure_bindings

              fish_vi_key_bindings
              set fish_cursor_default     block      blink
              set fish_cursor_insert      line       blink
              set fish_cursor_replace_one underscore blink
              set fish_cursor_visual      block

              # Correct cursor for ghostty when in VI mode.
              if string match -q -- '*ghostty*' $TERM
                set -g fish_vi_force_cursor 1
              end
            '';
            shellAliases.wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';
            shellAbbrs = {
              vim = "nvim";
              n = "nvim";
              cd = "z";
              cdi = "zi";
              cp = "xcp";
              grep = "rg";
              dig = "doggo";
              cat = "bat";
              curl = "curlie";
              rm = "gomi";
              ping = "gping";
              ls = "eza";
              sl = "eza";
              l = "eza --group --header --group-directories-first --long --git --all --binary --all --icons always";
              tree = "eza --tree";
              sudo = "sudo -E";
              k = "kubectl";
              kgp = "kubectl get pods";
              tsu = "tailscale up";
              tsd = "tailscale down";
              nhh = "nh home switch";
              nho = "nh os switch";
              nhu = "nh os --update";
              nd = "nix develop";
              nfu = "nix flake update";
              hms = "home-manager switch --flake ~/nixicle#${config.home.username}@(hostname)";
              nrs = "sudo nixos-rebuild switch --flake ~/nixicle#(hostname)";
              weather = "curl wttr.in/London";
              pfile = "fzf --preview 'bat --style=numbers --color=always --line-range :500 {}'";
              gdub = "git fetch -p && git branch -vv | grep ': gone]' | awk '{print }' | xargs git branch -D $argv;";
              tldrf = ''${pkgs.tldr}/bin/tldr --list | fzf --preview "${pkgs.tldr}/bin/tldr {1} --color" --preview-window=right,70% | xargs tldr'';
              wcat = "wellcat";
              imp = "sudo ${pkgs.fd}/bin/fd --one-file-system --base-directory / --type f --hidden --exclude '{tmp,etc/passwd,var/lib/systemd/coredump,proc,sys,dev,run,nix,boot}'";
            };
            functions = {
              fish_greeting = "";
              envsource = ''
                for line in (cat $argv | grep -v '^\s*#' | grep -v '^\s*$')
                    set item (string split -m 1 '=' $line)
                    if test (count $item) -eq 2
                        set -gx $item[1] $item[2]
                        echo "Exported key $item[1]"
                    end
                end
              '';
              gcrb = ''
                  set result (git branch -a --color=always | grep -v '/HEAD\s' | sort |
                    fzf --height 50% --border --ansi --tac --preview-window right:70% \
                      --preview 'git log --oneline --graph --date=short --pretty="format:%C(auto)%cd %h%d %s" (string sub -s 3 (string split ' ' {})[1]) | head -'$LINES |
                    string sub -s 3 | string split ' ' -m 1)[1]

                  if test -n "$result"
                    if string match -r "^remotes/.*" $result > /dev/null
                      git checkout --track (string replace -r "^remotes/" "" $result)
                    else
                      git checkout $result
                    end
                  end
                end
              '';
              hmg = ''
                set current_gen (home-manager generations | head -n 1 | awk '{print $7}')
                set selected (home-manager generations | tac | fzf --preview "nvd --color=always diff $current_gen (echo {} | awk '{print \$7}')" | awk '{print $7}')
                if test -n "$selected"
                  bash $selected/activate
                end
              '';
              rgvim = ''
                rg --color=always --line-number --no-heading --smart-case "$argv" |
                  fzf --ansi \
                      --color "hl:-1:underline,hl+:-1:underline:reverse" \
                      --delimiter : \
                      --preview 'bat --color=always {1} --highlight-line {2}' \
                      --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
                      --bind 'enter:become(nvim {1} +{2})'
              '';
              nz = ''
                set -l dir $argv[1]
                set -l current_dir (pwd)
                if test -n "$dir"
                  if test -d "$dir"
                    z "$dir"
                  else
                    echo "Directory '$dir' does not exist"
                    return 1
                  end
                end
                set file (fd --type f --hidden --follow --exclude .git --exclude node_modules |
                  fzf --ansi \
                      --preview 'bat --color=always --style=numbers --line-range :500 {} 2>/dev/null || echo "Binary file or preview not available"' \
                      --preview-window 'up,60%,border-bottom' \
                      --header 'Select file to edit (Ctrl-/ toggle preview, Ctrl-C cancel)' \
                      --bind 'ctrl-/:change-preview-window(down|hidden|up)' \
                      --bind 'ctrl-y:execute-silent(echo {} | wl-copy 2>/dev/null || echo {} | xclip -selection clipboard 2>/dev/null || echo "Clipboard not available")')
                if test -n "$file"
                  nvim "$file"
                else
                  echo "No file selected"
                  if test -n "$dir" -a (pwd) != "$current_dir"
                    if gum confirm "Stay in directory $(pwd)?"
                      echo "Staying in $(pwd)"
                    else
                      cd "$current_dir"
                      echo "Returned to $current_dir"
                    end
                  end
                end
              '';
              wellcat = ''
                if test (count $argv) -eq 0
                  echo "Usage: wellcat <file_or_directory>"
                  return 1
                end
                for item in $argv
                  if not test -e "$item"
                    echo "Error: '$item' does not exist"
                    continue
                  end
                  if string match -q "*.md" "$item"; or string match -q "*.mdx" "$item"
                    glow "$item"
                  else if test -f "$item"
                    set mime_type (file --mime-type -b "$item")
                    if string match -q "image/*" "$mime_type"
                      if command -v chafa >/dev/null
                        chafa "$item"
                      else
                        echo "Image '$item': $mime_type (preview not available)"
                      end
                    else
                      bat --style=plain --theme ansi "$item"
                    end
                  else if test -d "$item"
                    eza --icons -l "$item"
                  end
                end
              '';
              pkill_fzf = ''
                ps aux | fzf --header-lines=1 \
                              --preview 'echo "Process Info:"; ps -p {2} -o pid,ppid,user,time,args' \
                              --bind 'enter:execute(kill {2})' \
                              --bind 'ctrl-k:execute(kill -9 {2})'
              '';
              fish_command_not_found = ''
                if contains $argv[1] $__command_not_found_confirmed_commands
                  or ${pkgs.gum}/bin/gum confirm --selected.background=2 "Run using comma?"
                  if not contains $argv[1] $__command_not_found_confirmed_commands
                    set -ga __fish_run_with_comma_commands $argv[1]
                  end
                  comma -- $argv
                  return 0
                else
                  __fish_default_command_not_found_handler $argv
                end
              '';
            };
            plugins = fishPlugins pkgs;
          };
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

        # Fish shell
        stylix.targets.fish.enable = false;

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
