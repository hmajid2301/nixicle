{ config, inputs, lib, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.waybar-hyprland;
    systemd = {
      enable = false;
    };
    settings = [
      {
        layer = "top";
        position = "top";
        height = 40;
        margin = "0 0 0 0";
        modules-left = [
          "custom/launcher"
          "wlr/workspaces"
          "custom/currentplayer"
          "custom/player"
          "custom/audio_idle_inhibitor"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "tray"
          "backlight"
          "pulseaudio"
          "temperature"
          "cpu"
          "memory"
          "battery"
          "network"
          "custom/pomodoro"
          "custom/power"
        ];
        "wlr/workspaces" = {
          format = "{icon}";
          sort-by-number = true;
          active-only = false;
          format-icons = {
            "1" = "  ";
            "2" = "  ";
            "3" = " 󰎞 ";
            "4" = " 󰌌 ";
            "5" = "  ";
            "6" = " 󱎓 ";
            "7" = "  ";
            urgent = "  ";
            focused = "  ";
            default = "  ";
          };
          on-click = "activate";
        };
        "custom/audio_idle_inhibitor" = {
          format = "{icon}";
          exec = "sway-audio-idle-inhibit --dry-print-both-waybar";
          exec-if = "which sway-audio-idle-inhibit";
          return-type = "json";
          format-icons = {
            output = "  ";
            input = "  ";
            output-input = "  ";
          };
        };
        "custom/pomodoro" = {
          format = " 󱎫  {}";
          exec = "uairctl fetch %";
          exec-if = "uairctl listen";
        };
        "custom/currentplayer" = {
          interval = 2;
          return-type = "json";
          #exec = jsonOutput "currentplayer" {
          #  pre = ''
          #    player="$(playerctl status -f "{{playerName}}" 2>/dev/null || echo "No player active" | cut -d '.' -f1)"
          #    count="$(playerctl -l | wc -l)"
          #    if ((count > 1)); then
          #      more=" +$((count - 1))"
          #    else
          #      more=""
          #    fi
          #  '';
          #  alt = "$player";
          #  tooltip = "$player ($count available)";
          #  text = "$more";
          #};
          format = "{icon}{}";
          format-icons = {
            "No player active" = " ";
            "Celluloid" = " ";
            "spotify" = " 阮";
            "ncspot" = " 阮";
            "qutebrowser" = "爵";
            "firefox" = " ";
            "discord" = " ﭮ ";
            "sublimemusic" = " ";
            "kdeconnect" = " ";
          };
          on-click = "playerctld shift";
          on-click-right = "playerctld unshift";
        };
        "custom/player" = {
          exec-if = "playerctl status";
          exec = ''playerctl metadata --format '{"text": "{{artist}} - {{title}}", "alt": "{{status}}", "tooltip": "{{title}} ({{artist}} - {{album}})"}' '';
          return-type = "json";
          interval = 1;
          max-length = 30;
          format = "{icon} {}";
          format-icons = {
            "Playing" = "契";
            "Paused" = " ";
            "Stopped" = "栗";
          };
          on-click = "playerctl play-pause";
        };
        battery = {
          states = {
            good = 80;
            warning = 50;
            critical = 15;
          };
          format = "{icon}  {capacity}%";
          format-alt = "{time}";
          format-full = "";
          format-charging = "  {capacity}%";
          format-plugged = "  {capacity}%";
          format-icons = [ " " " " " " " " " " ];
        };
        temperature = {
          interval = 1;
          tooltip = false;
          thermal-zone = 1;
          critical-threshold = 80;
          format = "{icon} {temperatureC}°C";
          format-critical = "{icon} {temperatureC}°C";
          format-icons = [ "" "" "" "" "" ];
        };
        cpu = {
          interval = 1;
          tooltip = false;
          format = " {usage}%";
        };
        memory = {
          interval = 30;
          format = "󰍛 {used:0.1f}GiB";
          tooltip-format = "{used = 0.1f}GiB/{avail = 0.1f}GiB";
        };
        network = {
          interval = 1;
          format-wifi = "  {essid} {signalStrength}%";
          tooltip-format-wifi = "IP = {ipaddr}\nSSID = {essid}";
          format-ethernet = "";
          tooltip-format-ethernet = "IP = {ipaddr}";
          format-disconnected = "Disconnected ⚠";
          tooltip-format = ''
            {ifname}
            {ipaddr}/{cidr}
            Up: {bandwidthUpBits}
            Down: {bandwidthDownBits}'';
        };
        backlight = {
          tooltip = false;
          format = " {percent}%";
        };
        pulseaudio = {
          scroll-step = 2;
          format = "{icon} {volume}%";
          format-bluetooth = " {icon} {volume}%";
          format-muted = "";
          format-icons = {
            headphone = "";
            headset = "";
            default = [ "" "" ];
          };
        };
        clock = {
          format = "  {:%a %d %b  %I:%M %p}";
          format-alt = "  {:%d/%m/%Y  %H:%M:%S}";
          interval = 1;
          calendar = {
            mode = "year";
            "mode-mon-col" = 3;
            "weeks-pos" = "right";
            "on-scroll" = 1;
            "on-click-right" = "mode";
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            "on-click-right" = "mode";
            "on-click-forward" = "tz_up";
            "on-click-backward" = "tz_down";
            "on-scroll-up" = "shift_up";
            "on-scroll-down" = "shift_down";
          };
        };
        tray = {
          icon-size = 16;
          spacing = 8;
        };
        "custom/power" = {
          format = " ⏻ ";
          on-click = "~/dotfiles/home-manager/desktops/hyprland/scripts/power_menu.sh";
          tooltip = false;
        };
        "custom/launcher" = {
          format = "   ";
          tooltip = ''$(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f2)'';
          on-click = "rofi --show drun";
        };
      }
    ];
    style = (import ./styles.nix {
      inherit (config) fontProfiles colorscheme;
    });
  };
}

