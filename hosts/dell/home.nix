{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Audio utility scripts for Dell laptop
  elgato-fix = pkgs.writeScriptBin "elgato-fix" ''
    #!/usr/bin/env bash

    # Inspired by: https://gist.github.com/agners/48521cc7677d3134d9861ea0484724f4

    # Getting Elgato Wave:3 Microphone input "unstuck" on Linux & PipeWire
    # Replace <card-name> with your microphone's card name (check "pactl list cards")
    # It looks something like "alsa_card.usb-Elgato_Systems_Elgato_Wave_3_<serial>-00"
    card_name="alsa_card.usb-Elgato_Systems_Elgato_Wave_3_BS35M1A01828-00"

    ${pkgs.pulseaudio}/bin/pactl set-card-profile $card_name output:analog-stereo
    ${pkgs.pulseaudio}/bin/pactl set-card-profile $card_name input:mono-fallback
  '';

  toggle-headphones = pkgs.writeScriptBin "toggle-headphones" ''
    #!/usr/bin/env bash

    SOURCE1="alsa_card.usb-SteelSeries_Arctis_Nova_Pro_Wireless-00"
    SOURCE2="alsa_card.usb-ACTIONS_Pebble_V3-00.pro-output-0"

    CURRENT_SOURCE=$(${pkgs.pulseaudio}/bin/pactl info | grep "Default Sink" | awk '{print $3}')

    if [ "$CURRENT_SOURCE" = "$SOURCE1" ]; then
        ${pkgs.pulseaudio}/bin/pactl set-default-sink "$SOURCE2"
        echo "Switched to $SOURCE2"
    else
        ${pkgs.pulseaudio}/bin/pactl set-default-sink "$SOURCE1"
        echo "Switched to $SOURCE1"
    fi
  '';
in
{
  roles = {
    desktop.enable = true;
    non-nixos.enable = true;
  };

  development.android.emulator.enable = true;

  # TODO: Re-enable once import-tree issue is resolved
  # cli.tools.envoluntary.config = {
  #   # Install envoluntary with: cargo install envoluntary
  #   entries = [
  #     # Example: Load Node.js dev shell for website projects
  #     # {
  #     #   pattern = ".*/projects/my-website(/.*)?";
  #     #   flake_reference = "~/nix-dev-shells/nodejs";
  #     #   impure = true;
  #     # }
  #   ];
  # };

  home.packages = with pkgs; [
    # Audio utility scripts
    elgato-fix
    toggle-headphones
    
    # Development tools
    semgrep
    pre-commit
    bun
    
    # Fonts
    pkgs.nixicle.monolisa
    pkgs.noto-fonts-color-emoji
    pkgs.noto-fonts
    pkgs.source-serif
    pkgs.nerd-fonts.symbols-only
    pkgs.dejavu_fonts
    pkgs.liberation_ttf
  ];

  sops.defaultSymlinkPath = lib.mkForce "/run/user/1003/secrets";
  sops.defaultSecretsMountPoint = lib.mkForce "/run/user/1003/secrets.d";

  styles.stylix.enable = lib.mkForce false;
  stylix = lib.mkForce {
    enable = false;
    autoEnable = false;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };

  programs.ghostty.settings = {
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

  desktops = {
    niri = {
      enable = true;
    };

    addons = {
      noctalia = {
        laptop = true;
      };
    };
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
    Path = {
      PathChanged = "/proc/acpi/button/lid/LID0/state";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  fonts.fontconfig.enable = true;

  xdg = {
    mimeApps.defaultApplications = lib.mkForce {
      "text/html" = [ "google-chrome.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
      "x-scheme-handler/about" = [ "google-chrome.desktop" ];
      "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
    };

    configFile."fontconfig/conf.d/99-custom-fonts.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <test qual="any" name="family">
            <string>sans-serif</string>
          </test>
          <edit name="family" mode="assign">
            <string>Noto Sans</string>
          </edit>
        </match>

        <match target="pattern">
          <test qual="any" name="family">
            <string>serif</string>
          </test>
          <edit name="family" mode="assign">
            <string>Source Serif</string>
          </edit>
        </match>

        <match target="pattern">
          <test qual="any" name="family">
            <string>monospace</string>
          </test>
          <edit name="family" mode="assign">
            <string>MonoLisa</string>
          </edit>
        </match>

        <match target="pattern">
          <test name="family">
            <string>monospace</string>
          </test>
          <edit name="family" mode="append">
            <string>Symbols Nerd Font</string>
          </edit>
        </match>

        <match target="pattern">
          <test name="family">
            <string>monospace</string>
          </test>
          <edit name="family" mode="append">
            <string>DejaVu Sans Mono</string>
          </edit>
        </match>

        <match target="pattern">
          <test name="family">
            <string>sans-serif</string>
          </test>
          <edit name="family" mode="append">
            <string>DejaVu Sans</string>
          </edit>
        </match>

        <match target="pattern">
          <test name="family">
            <string>sans-serif</string>
          </test>
          <edit name="family" mode="append">
            <string>Symbols Nerd Font</string>
          </edit>
        </match>

        <match target="pattern">
          <test name="family">
            <string>emoji</string>
          </test>
          <edit name="family" mode="assign">
            <string>Noto Color Emoji</string>
          </edit>
        </match>
      </fontconfig>
    '';
  };

  cli.tools.git = {
    allowedSigners = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUF0LHH63pGkd1m7FGdbZirVXULDS5WSDzerJ0sskoq haseeb.majid@nala.money";
    email = "haseeb.majid@nala.money";
  };



  home.stateVersion = "23.11";
}
