{ den, ... }:
{
  den.aspects.haseebmajid = {
    includes = [
      den.aspects.desktopProfile
      den.aspects.non-nixos
    ];

    homeManager =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      {
        home = {
          stateVersion = "23.11";

          # Android emulator + extra packages (merged)
          packages = with pkgs; [
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
            semgrep
            pre-commit
            bun
            awscli2
            terraform
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

        sops.defaultSymlinkPath = lib.mkForce "/run/user/1003/secrets";
        sops.defaultSecretsMountPoint = lib.mkForce "/run/user/1003/secrets.d";

        # Lock on suspend (e.g. lid close) on this Ubuntu host.
        #
        # noctalia's own `general.lockOnSuspend` does not listen for logind's
        # sleep signals, so a system-initiated suspend resumes unlocked
        # (noctalia-shell issues #2569 / #1066). The shared lock-before-sleep
        # service from the niri aspect uses `dbus-monitor --system`, which
        # needs the D-Bus BecomeMonitor interface — NixOS's bus policy allows
        # it but Ubuntu's rejects it, so on this host it silently never fires.
        #
        # Fix: use swayidle's `-w before-sleep` hook, the approach the niri +
        # noctalia community settled on. The `-w` flag makes swayidle hold a
        # logind delay inhibitor, run the lock command, WAIT for it to return,
        # then release — the race-free "inhibit → lock → release" sequence the
        # systemd docs require (watching PrepareForSleep without an inhibitor
        # held first is racy). swayidle uses logind's inhibitor API as an
        # ordinary client, so it works under Ubuntu's bus policy too.
        #
        # Neutralise the shared service and run swayidle instead. Ordered
        # after niri-env-setup so WAYLAND_DISPLAY/NIRI_SOCKET are in the user
        # environment.
        systemd.user.services.lock-before-sleep.Install.WantedBy = lib.mkForce [ ];

        systemd.user.services.swayidle-lock = {
          Unit = {
            Description = "swayidle: lock noctalia before sleep";
            PartOf = [ "graphical-session.target" ];
            After = [
              "graphical-session.target"
              "niri-env-setup.service"
            ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.swayidle}/bin/swayidle -w before-sleep '${config.programs.noctalia-shell.package}/bin/noctalia-shell ipc call lockScreen lock || ${pkgs.systemd}/bin/loginctl lock-session'";
            Restart = "on-failure";
            RestartSec = 2;
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };

        programs = {
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

          noctalia-shell.settings = {
            idle = {
              enabled = true;
              screenOffTimeout = 330;
              lockTimeout = 300;
              suspendTimeout = 900;
              fadeDuration = 5;
            };
            bar.widgets.right = lib.mkBefore [
              {
                id = "Bluetooth";
                displayMode = "icon";
              }
              {
                id = "Brightness";
                displayMode = "onhover";
              }
              { id = "Battery"; }
            ];
            controlCenter.shortcuts.right = lib.mkBefore [
              { id = "PowerProfile"; }
            ];
          };
        };

        fonts.fontconfig.enable = true;

        xdg.mimeApps.defaultApplications = lib.mkForce {
          "text/html" = [ "google-chrome.desktop" ];
          "x-scheme-handler/http" = [ "google-chrome.desktop" ];
          "x-scheme-handler/https" = [ "google-chrome.desktop" ];
          "x-scheme-handler/about" = [ "google-chrome.desktop" ];
          "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
        };

        programs.git = {
          settings.user.email = lib.mkForce "haseeb.majid@nala.money";
          signing = {
            format = "ssh";
            signByDefault = true;
          };
        };
        home.file.".ssh/allowed_signers".text =
          "* ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUF0LHH63pGkd1m7FGdbZirVXULDS5WSDzerJ0sskoq haseeb.majid@nala.money";
      };
  };
}
