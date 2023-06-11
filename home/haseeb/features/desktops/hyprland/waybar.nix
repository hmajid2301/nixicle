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
        height = 30;
        margin =  "0 0 0 0";
        modules-left = [
          "custom/launcher"
          "wlr/workspaces"
          "tray"
          "mpd#2"
          "mpd#3"
          "mpd#4"
          "mpd"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "backlight"
          "pulseaudio"
          "temperature"
          "memory"
          "battery"
          "network"
          "custom/power"
        ];
        "wlr/workspaces" =  {
          format =  "{icon}";
          sort-by-number =  true;
          active-only =  false;
          format-icons =  {
            "1" =  "";
            "2" =  "";
            "3" =  "";
            "4" =  "";
            "5" =  "";
            "6" =  "";
            urgent =  "";
            focused =  "";
            default =  "";
          };
          on-click =  "activate";
        };
        mpd = {
          tooltip =  true;
          tooltip-format =  "{artist} - {album} - {title} - Total Time  =  {totalTime = %M = %S}";
          format =  " {elapsedTime = %M = %S}";
          format-disconnected =  "⚠  Disconnected";
          format-stopped =  " Not Playing";
          on-click =  "mpc toggle";
          state-icons =  {
            playing =  "";
            paused =  "";
          };
        };
        "mpd#2" =  {
          format =  "";
          format-disconnected =  "";
          format-paused =  "";
          format-stopped =  "";
          on-click =  "mpc -q pause && mpc -q prev && mpc -q start";
        };
        "mpd#3" =  {
          interval =  1;
          format =  "{stateIcon}";
          format-disconnected =  "";
          format-paused =  "{stateIcon}";
          format-stopped =  "";
          state-icons =  {
            paused =  "";
            playing =  "";
          };
          on-click =  "mpc toggle";
        };
        "mpd#4" =  {
          format =  "";
          format-disconnected =  "";
          format-paused =  "";
          format-stopped =  "";
          on-click =  "mpc -q pause && mpc -q next && mpc -q start";
        };
        battery = {
          states = {
            good = 95;
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-alt = "{time}";
          format-full = "";
          format-charging = "  {capacity}%";
          format-plugged = "  {capacity}%";
          format-icons = [ "" "" "" "" "" ];
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
          interval = 1;
          format = "󰍛 {percentage}%";
          tooltip-format = "{used = 0.1f}GiB/{avail = 0.1f}GiB";
        };
        network = {
          interval = 1;
          format-wifi = " {signalStrength}%";
          tooltip-format-wifi = "IP = {ipaddr}\nSSID = {essid}";
          format-ethernet = "";
          tooltip-format-ethernet = "IP = {ipaddr}";
          format-disconnected = "";
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
          tooltip = false;
          format = "{:%d/%m %H:%M}";
        };
        tray = {
          icon-size = 16;
          spacing = 8;
        };
        "custom/power" = {
          format = "⏻";
          on-click = "~/dotfiles/home/haseeb/features/desktops/hyprland/scripts/power_menu.sh";
          tooltip = false;
        };
        "custom/launcher" = {
          format = " ";
          on-click = "rofi --show drun";
          tooltip = false;
        };
      }
    ];
    style = let inherit (config.colorscheme) colors; in /* css */ ''
     @define-color base   #24273a;
     @define-color mantle #1e2030;
     @define-color crust  #181926;

     @define-color text     #cad3f5;
     @define-color subtext0 #a5adcb;
     @define-color subtext1 #b8c0e0;

     @define-color surface0 #363a4f;
     @define-color surface1 #494d64;
     @define-color surface2 #5b6078;

     @define-color overlay0 #6e738d;
     @define-color overlay1 #8087a2;
     @define-color overlay2 #939ab7;

     @define-color blue      #8aadf4;
     @define-color lavender  #b7bdf8;
     @define-color sapphire  #7dc4e4;
     @define-color sky       #91d7e3;
     @define-color teal      #8bd5ca;
     @define-color green     #a6da95;
     @define-color yellow    #eed49f;
     @define-color peach     #f5a97f;
     @define-color maroon    #ee99a0;
     @define-color red       #ed8796;
     @define-color mauve     #c6a0f6;
     @define-color pink      #f5bde6;
     @define-color flamingo  #f0c6c6;
     @define-color rosewater #f4dbd6;

     * {
          color: @lavender;
          border: 0;
          padding: 0 0;
          font-family: UbuntuMono;
          /* font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif; */
          /* font-family: "Hack Nerd Font"; */
          font-size: 18px;
          font-weight: bold;
          /* padding-bottom:4px;
          padding-top: 4px; */
      }

      window#waybar {
          border: 0px solid rgba(0, 0, 0, 0);
          /* border-radius: 10px; */
          /* background:#2d2a2e; */
          /* background-color: rgba(36, 39, 58, 0.85); */
          background-color: rgba(0, 0, 0, 0);
          /* background-color: shade(#1e1e2e, 0.95); */
      }

      #workspaces button {
          color: @base;
          border-radius: 50%;
          /* background-color: @base; */
          margin: 0px 0px;
          padding: 4 6 2 0;
          margin: 0px 8px 0px 8px;
      }

      #workspaces button:hover {
          color: @mauve;
          border-radius: 20px;
      }

      #workspaces * {
          color: whitesmoke;
      }

      #workspaces {
          border-style: solid;
          background-color: @base;
          opacity: 1;
          border-radius: 10px;
          margin: 8px 8px 8px 8px;
      }

      #workspaces button.active {
          color: @mauve;
          border-radius: 20px;
          /* background-color: @flamingo; */
      }

      #workspaces button {
        background-color: #${colors.base01};
        color: #${colors.base05};
        margin: 4px;
      }

      #workspaces button.hidden {
        background-color: #${colors.base00};
        color: #${colors.base04};
      }

      #workspaces button.focused,
      #workspaces button.active {
        background-color: #${colors.base0A};
        color: #${colors.base00};
      }

      #mode {
          color: #ebcb8b;
      }

      #clock,
      #custom-cava-internal,
      #battery,
      #cpu,
      #memory,
      #idle_inhibitor,
      #temperature,
      #backlight,
      #network,
      #pulseaudio,
      #mode,
      #tray,
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
          /* background-color:#a3be8c; */
          color: @sky;
          border-radius: 10px;
          margin: 8px 10px;
      }

      #backlight {
          color: @yellow;
          /* border-bottom: 2px solid @yellow; */
          border-radius: 10px 0 0 10px;
      }

      #battery {
          color: #d8dee9;
          /* border-bottom: 2px solid #d8dee9; */
          border-radius: 0 10px 10px 0;
          margin-right: 10px;
      }

      #battery.charging {
          color: #81a1c1;
          /* border-bottom: 2px solid #81a1c1; */
      }

      @keyframes blink {
          to {
              color: @red;
              /* border-bottom: 2px solid @red; */
          }
      }

      #battery.critical:not(.charging) {
          color: #bf616a;
          /* border-bottom: 2px solid #bf616a; */
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
      }

      #cpu {
          color: @sky;
          /* border-bottom: 2px solid @sky; */
      }

      #cpu #cpu-icon {
          color: @sky;
      }

      #memory {
          color: @sky;
      }

      #network.disabled {
          color: #bf616a;
          /* border-bottom: 2px solid #bf616a; */
      }

      #network {
          color: @green;
          /* border-bottom: 2px solid @green; */
          border-radius: 10px;
          margin-right: 5px;
      }

      #network.disconnected {
          color: #bf616a;
          /* border-bottom: 2px solid #bf616a; */
      }

      #pulseaudio {
          color: @flamingo;
          border-radius: 0 10px 10px 0;
          margin-right: 10px;
          /* border-bottom: 2px solid @flamingo; */
      }

      #pulseaudio.muted {
          color: #3b4252;
          /* border-bottom: 2px solid #3b4252; */
      }

      #temperature {
          color: @teal;
          /* border-bottom: 2px solid @teal; */
          border-radius: 10px 0 0 10px;
      }

      #temperature.critical {
          color: @red;
          /* border-bottom: 2px solid @red; */
      }

      #idle_inhibitor {
          background-color: #ebcb8b;
          color: @base;
      }

      #tray {
          /* background-color: @base; */
          margin: 8px 10px;
          border-radius: 10px;
      }

      #custom-launcher,
      #custom-power {}

      #custom-launcher {
          background-color: @mauve;
          color: @base;
          border-radius: 10px;
          padding: 5px 10px;
          margin-left: 15px;
      }

      #custom-power {
          color: @base;
          background-color: @red;
          border-radius: 10px;
          margin-left: 5px;
          margin-right: 15px;
          padding: 5px 10px;
      }

      #window {
          border-style: hidden;
          margin-left: 10px;
          /* margin-top:1px;  
          padding: 8px 1rem; */
          margin-right: 10px;
          color: #eceff4;
      }

      #mode {
          margin-bottom: 3px;
      }

      #custom-keyboard-layout {
          color: @peach;
          /* border-bottom: 2px solid @peach; */
          border-radius: 0 10px 10px 0;
          margin-right: 10px;
      }
   '';
  };
}

