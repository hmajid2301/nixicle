{
  pkgs,
  config,
  lib,
  inputs,
  hostIsLaptop,
  ...
}:
let
  inherit (config.lib.stylix) colors;
  inherit (config.lib.formats.rasi) mkLiteral;

  noctaliaPluginsDir = pkgs.runCommand "noctalia-plugins-nix" { } ''
    mkdir -p $out
    ln -s ${inputs.noctalia-community-plugins}/niri-displays $out/niri-displays
    ln -s ${inputs.noctalia-community-plugins}/phone-connect $out/phone-connect
    ln -s ${inputs.noctalia-community-plugins}/battery-power-management $out/battery-power-management
    ln -s ${inputs.noctalia-official-plugins}/bitwarden $out/bitwarden
  '';
in
{
  programs = {
    rofi = {
      enable = true;
      package = pkgs.rofi;
      terminal = "${pkgs.foot}/bin/foot";
      extraConfig = {
        modi = "run,drun,window";
        show-icons = true;
        drun-display-format = "{icon} {name}";
        location = 0;
        disable-history = false;
        hide-scrollbar = true;
        display-drun = "   Apps ";
        display-run = "   Run ";
        display-window = " 﩯  Window";
        display-Network = " 󰤨  Network";
        sidebar-mode = true;
      };
      theme = lib.mkForce {
        "*" = {
          bg-col = mkLiteral "#${colors.base00}";
          bg-col-light = mkLiteral "#${colors.base00}";
          border-col = mkLiteral "#${colors.base00}";
          selected-col = mkLiteral "#${colors.base00}";
          blue = mkLiteral "#${colors.base0D}";
          fg-col = mkLiteral "#${colors.base05}";
          fg-col2 = mkLiteral "#${colors.base08}";
          grey = "#737994";
          width = 600;
        };
        "element-text, element-icon , mode-switcher" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
        "window" = {
          height = mkLiteral "360px";
          border = mkLiteral "3px";
          border-color = mkLiteral "@border-col";
          background-color = mkLiteral "@bg-col";
        };
        "mainbox".background-color = mkLiteral "@bg-col";
        "inputbar" = {
          children = mkLiteral "[prompt,entry]";
          background-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "5px";
          padding = mkLiteral "2px";
        };
        "prompt" = {
          background-color = mkLiteral "@blue";
          padding = mkLiteral "6px";
          text-color = mkLiteral "@bg-col";
          border-radius = mkLiteral "3px";
          margin = mkLiteral "20px 0px 0px 20px";
        };
        "entry" = {
          padding = mkLiteral "6px";
          margin = mkLiteral "20px 0px 0px 10px";
          text-color = mkLiteral "@fg-col";
          background-color = mkLiteral "@bg-col";
        };
        "listview" = {
          border = mkLiteral "0px 0px 0px";
          padding = mkLiteral "6px 0px 0px";
          margin = mkLiteral "10px 0px 0px 20px";
          columns = 2;
          lines = 5;
          background-color = mkLiteral "@bg-col";
        };
        "element" = {
          padding = mkLiteral "5px";
          background-color = mkLiteral "@bg-col";
          text-color = mkLiteral "@fg-col";
        };
        "element-icon".size = mkLiteral "25px";
        "element selected" = {
          background-color = mkLiteral "@selected-col";
          text-color = mkLiteral "@fg-col2";
        };
        "mode-switcher".spacing = 0;
        "button" = {
          padding = mkLiteral "10px";
          background-color = mkLiteral "@bg-col-light";
          text-color = mkLiteral "@grey";
          vertical-align = mkLiteral "0.5";
          horizontal-align = mkLiteral "0.5";
        };
        "button selected" = {
          background-color = mkLiteral "@bg-col";
          text-color = mkLiteral "@blue";
        };
        "message" = {
          background-color = mkLiteral "@bg-col-light";
          margin = mkLiteral "2px";
          padding = mkLiteral "2px";
          border-radius = mkLiteral "5px";
        };
        "textbox" = {
          padding = mkLiteral "6px";
          margin = mkLiteral "20px 0px 0px 20px";
          text-color = mkLiteral "@blue";
          background-color = mkLiteral "@bg-col-light";
        };
      };
    };

    noctalia = {
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
        location = {
          address = "london";
        };
        weather = {
          enabled = true;
        };
        control_center.calendar = {
          show_events_card = true;
        };
        dock = {
          enabled = false;
        };
        bar.main = {
          margin_edge = 8;
          margin_ends = 8;
          start = [ "workspaces" ];
          center = [ "clock" "caffeine" ];
          end =
            [
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
        widget.workspaces = {
          max_label_chars = 2;
        };
        widget.clock = {
          format = "{:%H:%M:%S %a, %b %d}";
        };
        widget.notifications = {
          hide_when_no_unread = true;
        };
        widget.network = {
          show_label = false;
        };
        widget.bluetooth = lib.mkIf hostIsLaptop {
          show_label = false;
        };
        widget.brightness = lib.mkIf hostIsLaptop {
          show_label = false;
        };
        widget.volume = {
          show_label = false;
        };
        wallpaper = {
          directory = "/home/${config.home.username}/nixicle/packages/wallpapers/wallpapers";
        };
        lockscreen = {
          lock_before_suspend = true;
        };
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
      };
    };

    wlogout = {
      enable = true;
      layout = [
        {
          label = "lock";
          action = "noctalia msg session lock";
          text = "Lock";
          keybind = "l";
        }
        {
          label = "hibernate";
          action = "systemctl hibernate";
          text = "Hibernate";
          keybind = "h";
        }
        {
          label = "logout";
          action = "loginctl terminate-user $USER";
          text = "Logout";
          keybind = "L";
        }
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "S";
        }
        {
          label = "suspend";
          action = "systemctl suspend";
          text = "Suspend";
          keybind = "s";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "Reboot";
          keybind = "r";
        }
      ];
      style = builtins.readFile ./wlogout-style.css;
    };

    cava = {
      enable = true;
      settings = {
        general = {
          bars = 0;
          framerate = 60;
          stereo = false;
          sensitivity = 100;
          autosens = 1;
          lower_cutoff_freq = 50;
          higher_cutoff_freq = 10000;
        };
        input = {
          method = "pipewire";
          source = "auto";
        };
        output = {
          method = "ncurses";
          orientation = "bottom";
          channels = "stereo";
        };
        color = {
          gradient = 1;
          gradient_count = 6;
          gradient_color_1 = "'#${colors.base08}'";
          gradient_color_2 = "'#${colors.base09}'";
          gradient_color_3 = "'#${colors.base0A}'";
          gradient_color_4 = "'#${colors.base0B}'";
          gradient_color_5 = "'#${colors.base0C}'";
          gradient_color_6 = "'#${colors.base0D}'";
        };
        smoothing = {
          monstercat = 1;
          waves = 0;
          gravity = 100;
          ignore = 0;
        };
      };
    };
  };
}
