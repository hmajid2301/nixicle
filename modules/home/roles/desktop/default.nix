{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.roles.desktop;
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
in {
  options.roles.desktop = {
    enable = mkEnableOption "Enable desktop suite";
  };

  config = mkIf cfg.enable {
    roles = {
      common.enable = true;
      development.enable = true;
    };

    services = {
      nixicle.kdeconnect.enable = true;
      spotify.enable = true;
    };
    desktops.addons.xdg.enable = true;

    home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      QT_QPA_PLATFORM = "wayland;xcb";
      LIBSEAT_BACKEND = "logind";
    };

    # TODO: move this to somewhere
    home.packages = with pkgs; [
      elgato-fix
      toggle-headphones

      mplayer
      mtpfs
      jmtpfs
      brightnessctl
      xdg-utils
      wl-clipboard
      clipse
      pamixer
      playerctl

      grimblast
      slurp
      sway-contrib.grimshot
      pkgs.satty
    ];
  };
}
