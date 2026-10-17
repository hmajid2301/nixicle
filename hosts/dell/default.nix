{ inputs, den, ... }:
{
  den.aspects.haseebmajid = {
    includes = [
      den.aspects.desktopProfile
      den.aspects.non-nixos
      den.aspects.claude-code
    ];

    homeManager =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        # Determinate Nix owns /etc/nix/nix.conf (lazy-trees, eval-cores);
        # nixpkgs' nix on the activation PATH warns "unknown setting" on both.
        # `nix.package = null` matches determinate's own homeManagerModules,
        # but it stops HM writing nix.conf, so render it from the settings the
        # aspects (attic-client, neovim, noctalia) still define.
        # HM asserts a package whenever nix.settings is non-empty, so clear it
        # and write the same values ourselves.
        nix = {
          package = lib.mkForce null;
          settings = lib.mkForce { };
        };

        sops = {
          secrets.nix_access_tokens.sopsFile = lib.nixicle.secretsFile;
          defaultSymlinkPath = lib.mkForce "/run/user/1003/secrets";
          defaultSecretsMountPoint = lib.mkForce "/run/user/1003/secrets.d";
        };

        xdg = {
          configFile."nix/nix.conf".text =
            let
              atticKey = "main:+A4BR+E8F8FNe1YR6Uq8qGO5dVj8y1kaalW3kQ0WgXo=";
              substituters = [
                "https://nix-community.cachix.org"
                "https://attic.${lib.nixicle.domains.root}/main"
                "https://catppuccin.cachix.org"
                "https://noctalia.cachix.org"
              ];
              keys = [
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                atticKey
                "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
                "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
              ];
            in
            ''
              extra-substituters = ${lib.concatStringsSep " " substituters}
              extra-trusted-public-keys = ${lib.concatStringsSep " " keys}
              netrc-file = ${config.sops.secrets."netrc".path}
              !include ${config.sops.secrets.nix_access_tokens.path}
            '';

          mimeApps.defaultApplications = lib.mkForce {
            "text/html" = [ "google-chrome.desktop" ];
            "x-scheme-handler/http" = [ "google-chrome.desktop" ];
            "x-scheme-handler/https" = [ "google-chrome.desktop" ];
            "x-scheme-handler/about" = [ "google-chrome.desktop" ];
            "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
          };
        };

        home = {
          stateVersion = "23.11";

          # Android emulator + extra packages (merged)
          packages = with pkgs; [
            # The niri session is launched under nixGLIntel with
            # hm-session-vars.sh sourced, so every process inherits a Nix
            # GI_TYPELIB_PATH (glib-2.88.1, gtk4, ...) and Nix libs on
            # LD_LIBRARY_PATH. Ubuntu's Python `gi` powerprofilesctl then loads
            # the Nix glib typelib against a mismatched glib and dies with
            # `undefined symbol: g_string_copy`. Strip the Nix env so it uses
            # the system stack — same fix as the google-chrome wrapper below.
            # noctalia's PowerProfile control-center widget shells out here too.
            (lib.hiPrio (
              pkgs.writeShellScriptBin "powerprofilesctl" ''
                unset GI_TYPELIB_PATH
                export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -v /nix/store | tr '\n' ':' | sed 's/:*$//')
                exec /usr/bin/powerprofilesctl "$@"
              ''
            ))
            (pkgs.writeShellScriptBin "android-emulator" ''
              export QT_QPA_PLATFORM=xcb
              unset __EGL_VENDOR_LIBRARY_FILENAMES
              unset GBM_BACKENDS_PATH
              export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu
              export LIBGL_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri
              EMULATOR_BIN="''${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}/emulator/emulator"
              if [ ! -f "$EMULATOR_BIN" ]; then
                ${pkgs.gum}/bin/gum style --foreground 196 "Error: Android emulator not found at $EMULATOR_BIN"; exit 1
              fi
              AVDS=$("$EMULATOR_BIN" -list-avds)
              if [ -z "$AVDS" ]; then
                ${pkgs.gum}/bin/gum style --foreground 196 "No Android Virtual Devices found!"; exit 1
              fi
              SELECTED=$(echo "$AVDS" | ${pkgs.gum}/bin/gum choose --header "Select an Android Virtual Device:")
              if [ -z "$SELECTED" ]; then exit 0; fi
              exec "$EMULATOR_BIN" -avd "$SELECTED" -gpu host "$@"
            '')
            gum
            android-tools
            (pkgs.writeScriptBin "elgato-fix" ''
              #!/usr/bin/env bash
              card_name="alsa_card.usb-Elgato_Systems_Elgato_Wave_3_BS35M1A01828-00"
              ${pkgs.pulseaudio}/bin/pactl set-card-profile $card_name output:analog-stereo
              ${pkgs.pulseaudio}/bin/pactl set-card-profile $card_name input:mono-fallback
            '')
            (pkgs.writeScriptBin "toggle-headphones" ''
              #!/usr/bin/env bash
              SOURCE1="alsa_card.usb-SteelSeries_Arctis_Nova_Pro_Wireless-00"
              SOURCE2="alsa_card.usb-ACTIONS_Pebble_V3-00.pro-output-0"
              CURRENT_SOURCE=$(${pkgs.pulseaudio}/bin/pactl info | grep "Default Sink" | awk '{print $3}')
              if [ "$CURRENT_SOURCE" = "$SOURCE1" ]; then
                  ${pkgs.pulseaudio}/bin/pactl set-default-sink "$SOURCE2"
              else
                  ${pkgs.pulseaudio}/bin/pactl set-default-sink "$SOURCE1"
              fi
            '')
            # TODO(nixpkgs): pr=569851 input=nixpkgs package=semgrep target=homeConfigurations."haseebmajid@dell".activationPackage
            # semgrep
            pre-commit
            bun
            awscli2
            terraform
            (
              let
                nixGL = inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel;
              in
              pkgs.symlinkJoin {
                name = "cursor-nixgl-${pkgs.code-cursor.version}";
                paths = [ pkgs.code-cursor ];
                nativeBuildInputs = [ pkgs.makeWrapper ];
                postBuild = ''
                  rm "$out/bin/cursor"
                  makeWrapper "${nixGL}/bin/nixGLIntel" "$out/bin/cursor" \
                    --add-flags "${pkgs.code-cursor}/bin/cursor" \
                    --add-flags "--no-sandbox" \
                    --add-flags "--password-store=gnome-libsecret"
                '';
              }
            )
            nixicle.monolisa
            noto-fonts-color-emoji
            noto-fonts
            source-serif
            nerd-fonts.symbols-only
            dejavu_fonts
            liberation_ttf
          ];

          sessionVariables = {
            ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
            ANDROID_HOME = "$HOME/Android/Sdk";
          };

          file.".local/bin/adb-wrapper".source = pkgs.writeShellScript "adb-wrapper" ''
            export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
            export ANDROID_HOME="$HOME/Android/Sdk"
            exec ${pkgs.android-tools}/bin/adb "$@"
          '';
        };

        xdg.configFile."envoluntary/config.toml".source =
          (pkgs.formats.toml { }).generate "envoluntary-config.toml"
            {
              entries = [
                {
                  pattern = "~/projects/vault-plugins(/.*)?";
                  flake_reference = "~/nix-dev-shells/vault-plugins";
                  impure = true;
                }
                {
                  pattern = "~/projects/terraform-aws(/.*)?";
                  flake_reference = "~/nix-dev-shells/terraform-aws";
                  impure = true;
                }
              ];
            };

        # v5 [lockscreen].lock_before_suspend handles logind sleep signals natively.
        # Noctalia's own idle service replaces the swayidle workaround.

        programs = {
          worktrunk.settings.projects."github.com/NalaMoney/nala-backend".post-start.copy =
            "wt step copy-ignored";
          git = {
            settings.user.email = lib.mkForce "haseeb.majid@nala.money";
            signing = {
              format = "ssh";
              signByDefault = true;
            };
          };
          ghostty.settings = {
            "font-family" = [
              "MonoLisa"
              "Symbols Nerd Font"
              "Noto Color Emoji"
            ];
            theme = "Catppuccin Mocha";
            command = "fish";
            gtk-titlebar = false;
            gtk-tabs-location = "hidden";
            gtk-single-instance = true;
            font-size = 14;
            window-padding-x = 6;
            window-padding-y = 6;
            copy-on-select = "clipboard";
            cursor-style = "block";
            confirm-close-surface = false;
            keybind = [ "ctrl+shift+plus=increase_font_size:1" ];
          };

          noctalia.settings = {
            idle = {
              pre_action_fade_seconds = 5.0;
              behavior = {
                lock = {
                  timeout = 300;
                  action = "lock";
                };
                screen-off = {
                  timeout = 330;
                  action = "screen_off";
                };
                suspend = {
                  timeout = 900;
                  action = "lock_and_suspend";
                };
              };
            };
          };
        };

        fonts.fontconfig.enable = true;

        home.file.".ssh/allowed_signers".text =
          "* ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUF0LHH63pGkd1m7FGdbZirVXULDS5WSDzerJ0sskoq haseeb.majid@nala.money";
      };
  };
}
