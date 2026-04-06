{ den, ... }:
{
  den.aspects.haseebmajid.provides.dell = {
    includes = [
      den.aspects.desktop
      den.aspects.non-nixos
    ];

    homeManager = { pkgs, lib, config, ... }: {
      home.stateVersion = "23.11";

      # Android emulator
      home.packages = with pkgs; [
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
        gum android-tools
      ];
      home.sessionVariables = {
        ANDROID_SDK_ROOT = "$HOME/Android/Sdk";
        ANDROID_HOME = "$HOME/Android/Sdk";
      };
      home.file.".local/bin/adb-wrapper".source = pkgs.writeShellScript "adb-wrapper" ''
        export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
        export ANDROID_HOME="$HOME/Android/Sdk"
        exec ${pkgs.android-tools}/bin/adb "$@"
      '';

      xdg.configFile."envoluntary/config.toml".source = (pkgs.formats.toml { }).generate "envoluntary-config.toml" {
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

      home.packages = with pkgs; [
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
        nixicle.monolisa
        noto-fonts-color-emoji
        noto-fonts
        source-serif
        nerd-fonts.symbols-only
        dejavu_fonts
        liberation_ttf
      ];

      sops.defaultSymlinkPath = lib.mkForce "/run/user/1003/secrets";
      sops.defaultSecretsMountPoint = lib.mkForce "/run/user/1003/secrets.d";

      stylix = lib.mkForce {
        enable = false;
        autoEnable = false;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      };

      programs.ghostty.settings = {
        "font-family" = [ "MonoLisa" "Symbols Nerd Font" "Noto Color Emoji" ];
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

      # Noctalia laptop widgets (battery, brightness, bluetooth)
      programs.noctalia-shell.settings = {
        bar.widgets.right = lib.mkBefore [
          { id = "Bluetooth"; displayMode = "icon"; }
          { id = "Brightness"; displayMode = "onhover"; }
          { id = "Battery"; }
        ];
        controlCenter.shortcuts.right = lib.mkBefore [
          { id = "PowerProfile"; }
        ];
      };

      systemd.user.services.suspend-on-lid-close = {
        Unit = {
          Description = "Suspend system on lid close";
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl suspend";
        };
      };

      systemd.user.paths.suspend-on-lid-close = {
        Unit = {
          Description = "Monitor lid switch for suspend trigger";
          PartOf = [ "graphical-session.target" ];
        };
        Path.PathChanged = "/proc/acpi/button/lid/LID0/state";
        Install.WantedBy = [ "graphical-session.target" ];
      };

      fonts.fontconfig.enable = true;

      xdg.mimeApps.defaultApplications = lib.mkForce {
        "text/html" = [ "google-chrome.desktop" ];
        "x-scheme-handler/http" = [ "google-chrome.desktop" ];
        "x-scheme-handler/https" = [ "google-chrome.desktop" ];
        "x-scheme-handler/about" = [ "google-chrome.desktop" ];
        "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
      };

      programs.git.settings.user.email = "haseeb.majid@nala.money";
      home.file.".ssh/allowed_signers".text = "* ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUF0LHH63pGkd1m7FGdbZirVXULDS5WSDzerJ0sskoq haseeb.majid@nala.money";

      gtk.gtk4.theme = null;

      programs.git.signing = {
        format = "ssh";
        signByDefault = true;
      };
    };
  };
}
