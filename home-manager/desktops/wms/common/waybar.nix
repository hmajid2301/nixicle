{ config, ... }:
let
  inherit (config) colorscheme fontProfiles;
in
{
  programs.waybar = {
    enable = true;
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
          (
            if config.wayland.windowManager.sway.enable
            then "sway/workspaces"
            else "hyprland/workspaces"
          )
          "custom/currentplayer"
          "custom/player"
          "custom/audio_idle_inhibitor"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "gamemode"
          "tray"
          "custom/notification"
          "idle_inhibitor"
          "pulseaudio"
          "temperature"
          "cpu"
          "memory"
          "backlight"
          "battery"
          "network"
          "custom/power"
        ];
        "sway/workspaces" = {
          format = "{icon}";
          sort-by-number = true;
          active-only = false;
          format-icons = {
            "1" = "  ";
            "2" = "  ";
            "3" = " 󰎞 ";
            "4" = " 󰒱 ";
            "5" = "  ";
            "6" = "  ";
            # urgent = "  ";
            # focused = "  ";
            # default = "  ";
          };
          on-click = "activate";
        };
        "hyprland/workspaces" = {
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
        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "  ";
            deactivated = "  ";
          };
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
          tooltip-format = "<tt><small>{calendar}</small></tt>";
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
        gamemode = {
          format = "{glyph}";
          "format-alt" = "{glyph} {count}";
          glyph = "\uf7b3";
          "hide-not-running" = true;
          "use-icon" = true;
          "icon-name" = "input-gaming-symbolic";
          "icon-spacing" = 4;
          "icon-size" = 20;
          tooltip = true;
          "tooltip-format" = "Games running: {count}";
        };
        "custom/notification" = {
          tooltip = false;
          format = "{} {icon}";
          "format-icons" = {
            notification = " <span foreground='red'><sup> </sup></span>";
            none = "  ";
            "dnd-notification" = "   <span foreground='red'><sup> </sup></span>";
            "dnd-none" = "   ";
            "inhibited-notification" = "  <span foreground='red'><sup> </sup></span>";
            "inhibited-none" = "  ";
            "dnd-inhibited-notification" = "  <span foreground='red'><sup> </sup></span>";
            "dnd-inhibited-none" = "   ";
          };
          "return-type" = "json";
          "exec-if" = "which swaync-client";
          exec = "swaync-client -swb";
          "on-click" = "swaync-client -t -sw";
          "on-click-right" = "swaync-client -d -sw";
          escape = true;
        };
        "custom/power" = {
          format = " ⏻ ";
          on-click = "rofi -show p -modi p:rofi-power-menu";
          tooltip = false;
        };
        "custom/launcher" = {
          format = "   ";
          on-click = "rofi -show drun -modi drun";
        };
      }
    ];

    style =
      # css
      ''
        @define-color base      #${colorscheme.colors.base00};
        @define-color blue      #${colorscheme.colors.base0D};
        @define-color rosewater #${colorscheme.colors.base06};
        @define-color lavender  #${colorscheme.colors.base07};
        @define-color teal      #${colorscheme.colors.base0C};
        @define-color yellow    #${colorscheme.colors.base0A};
        @define-color green     #${colorscheme.colors.base0B};
        @define-color red       #${colorscheme.colors.base08};
        @define-color mauve     #${colorscheme.colors.base0E};
        @define-color flamingo  #${colorscheme.colors.base0F};

        * {
         color: @lavender;
         border: 0;
         padding: 0 0;
         font-family: ${fontProfiles.monospace.family};
         font-size: 18px;
         font-weight: bold;
        }

        window#waybar {
         border: 0px solid rgba(0, 0, 0, 0);
         background-color: rgba(0, 0, 0, 0);
        }

        #workspaces * {
         color: white;
        }

        #workspaces {
         border-style: solid;
         background-color: @base;
         opacity: 1;
         border-radius: 10px;
         margin: 8px 8px 8px 8px;
        }

        #workspaces button {
         color: @base;
         border-radius: 20px;
         padding: 2px;
         margin: 2px 4px 0px 4px;
        }

        #workspaces button:hover {
         color: @mauve;
         border-radius: 20px;
        }


        #workspaces button.active * {
         color: @base;
         background-color: @mauve;
         border-radius: 20px;
        }

        #workspaces button.visible {
         color: white;
         background-color: @mauve;
         border-radius: 20px;
        }

        #workspaces button.visible * {
         color: white;
         color: @base;
        }

        #mode {
         color: @yellow;
        }

        #clock,
        #battery,
        #cpu,
        #memory,
        #temperature,
        #backlight,
        #network,
        #pulseaudio,
        #mode,
        #tray,
        #idle_inhibitor,
        #custom-power,
        #custom-launcher,
        #custom-notification,
        #mpd {
         padding: 5px 8px;
         border-style: solid;
         background-color: shade(@base, 1);
         opacity: 1;
         margin: 8px 0;
        }

        /* -----------------------------------------------------------------------------
        * Module styles
        * -------------------------------------------------------------------------- */
        #mpd {
         border-radius: 10px;
         color: @mauve;
         margin-left: 5px;
         background-color: rgba(0, 0, 0, 0);
        }

        #mpd.2 {
         border-radius: 10px 0px 0px 10px;
         margin: 8px 0px 8px 6px;
         padding: 4px 12px 4px 10px;
        }

        #mpd.3 {
         border-radius: 0px 0px 0px 0px;
         margin: 8px 0px 8px 0px;
         padding: 4px;
        }

        #mpd.4 {
         border-radius: 0px 10px 10px 0px;
         margin: 8px 0px 8px 0px;
         padding: 4px 10px 4px 14px;
        }

        #mpd.2,
        #mpd.3,
        #mpd.4 {
         background-color: @base;
         font-size: 14px;
        }

        #clock {
         color: @mauve;
         border-radius: 10px;
         margin: 8px 10px;
        }


        #backlight {
         color: @yellow;
         border-radius: 10px 0 0 10px;
         margin-left: 10px;
        }

        #battery {
         color: @yellow;
         border-radius: 0 10px 10px 0;
         margin-right: 10px;
        }

        #battery.critical:not(.charging) {
        color: @red;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
        }

        #battery.charging {
         color: @green;
        }

        @keyframes blink {
         to {
        		 color: @red;
         }
        }

        #custom-notification {
        	font-family: ${fontProfiles.monospace.family};
        	border-radius: 10px 0 0 10px;
        	margin-left: 10px;
        	color: @lavender;
        	background: @base;
        }

        #tray {
        	 margin: 8px 10px;
        	 border-radius: 10px;
        }

        #idle_inhibitor.deactivated {
        	background-color: shade(@base, 1);
        	color: @lavender;
        }

        #idle_inhibitor.activated {
        	 background-color: shade(@base, 1);
        	 color: @green;
        }

        #idle_inhibitor {
        	 background-color: @yellow;
        	 color: @base;
        }



        #pulseaudio {
        	 color: @flamingo;
        	 border-radius: 0 10px 10px 0;
        	 margin-right: 10px;
        }

        #pulseaudio.muted {
        	 color: #3b4252;
        }

        #temperature {
        	 color: @teal;
        	 border-radius: 10px 0 0 10px;
        }

        #temperature.critical {
        	 color: @red;
        }

        #cpu {
        	 color: @blue;
        }

        #cpu #cpu-icon {
        	 color: @blue;
        }

        #memory {
        	 color: @flamingo;
        	 border-radius: 0 10px 10px 0;
        	 margin-right: 5px;
        }

        #network {
        	 color: @lavender;
        	 border-radius: 10px;
        	 margin-right: 5px;
        }

        #network.disconnected {
        	 color: @red;
        }

        #custom-launcher {
        	 background-color: @mauve;
        	 color: @base;
        	 border-radius: 10px;
        	 padding: 5px 10px;
        	 margin-left: 15px;
        	 font-size: 24px;
        }

        #custom-power {
        	 margin: 8px;
        	 padding: 5px;
        	 border-radius: 10px;
        	 transition: none;
        	 color: @red;
        	 background: @base;
        }

        #window {
        	 border-style: hidden;
        	 margin-left: 10px;
        }

        #mode {
        	 margin-bottom: 3px;
        }
      '';
  };
}
