{
  config,
  pkgs,
  lib,
  inputs,
  hostIsLaptop,
  ...
}:
let
  noctaliaPluginsDir = pkgs.runCommand "noctalia-plugins-nix" { } ''
    mkdir -p $out
    ln -s ${inputs.noctalia-community-plugins}/niri-displays $out/niri-displays
    ln -s ${inputs.noctalia-community-plugins}/phone-connect $out/phone-connect
    ln -s ${inputs.noctalia-community-plugins}/battery-power-management $out/battery-power-management
    ln -s ${inputs.noctalia-official-plugins}/bitwarden $out/bitwarden
  '';
in
{
  config = {
    home.packages = with pkgs; [ bitwarden-cli ];

    nixicle.desktop.shell = {
      enable = lib.mkDefault config.programs.noctalia.enable;
      startup.args = lib.mkDefault [ "${config.programs.noctalia.package}/bin/noctalia" ];
      lockSuspend.args = lib.mkDefault [
        "${config.programs.noctalia.package}/bin/noctalia"
        "msg"
        "session"
        "lock-and-suspend"
      ];
    };

    programs.noctalia = {
      enable = true;
      settings = {
        shell = {
          font_family = config.stylix.fonts.sansSerif.name;
          clipboard_enabled = true;
          avatar_path = "/home/${config.home.username}/.face";
        };
        nightlight = {
          enabled = true;
          temperature_day = 6500;
          temperature_night = 4000;
        };
        location.address = "london";
        weather.enabled = true;
        control_center.calendar.show_events_card = true;
        dock.enabled = false;
        bar.main = {
          margin_edge = 8;
          margin_ends = 8;
          start = [ "workspaces" ];
          center = [
            "clock"
            "caffeine"
          ];
          end = [
            "tray"
            "notifications"
            "network"
          ]
          ++ lib.optionals hostIsLaptop [
            "bluetooth"
            "brightness"
            "battery"
          ]
          ++ [
            "volume"
            "control_center"
          ];
        };
        widget = {
          workspaces.max_label_chars = 2;
          clock.format = "{:%H:%M:%S %a, %b %d}";
          notifications.hide_when_no_unread = true;
          network.show_label = false;
          bluetooth = lib.mkIf hostIsLaptop {
            show_label = false;
          };
          brightness = lib.mkIf hostIsLaptop {
            show_label = false;
          };
          volume.show_label = false;
        };
        wallpaper.directory = "/home/${config.home.username}/nixicle/packages/wallpapers/wallpapers";
        lockscreen.lock_before_suspend = true;
        control_center.shortcuts = [
          { type = "wifi"; }
          { type = "bluetooth"; }
          { type = "screen_recorder"; }
          { type = "wallpaper"; }
          { type = "notification"; }
          { type = "nightlight"; }
        ];
        plugins = {
          enabled = [
            "raycursive/niri-displays"
            "noctalia/bitwarden"
            "icefish/phone-connect"
            "piero-93/battery-power-management"
          ];
          auto_update = "none";
          source = [
            {
              name = "nix-managed";
              kind = "path";
              location = "${noctaliaPluginsDir}";
              enabled = true;
            }
          ];
        };
        idle = lib.mkDefault {
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
  };
}
