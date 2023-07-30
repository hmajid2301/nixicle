{ colorscheme, fontProfiles, ... }:
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

  #workspaces button {
      color: @base;
      border-radius: 20px;
      margin: 2px 0px;
      padding: 4px;
      margin: 0px 8px 0px 8px;
  }

  #workspaces button:hover {
      color: @mauve;
      border-radius: 20px;
  }

  #workspaces button:hover * {
      color: @mauve;
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

  #workspaces button.active {
      color: white;
      background-color: @mauve;
      border-radius: 20px;
  }

  #workspaces button.active * {
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
  }

  #battery {
      color: @yellow;
      border-radius: 0 10px 10px 0;
      margin-right: 10px;
  }

  #battery.charging {
      color: @green;
  }

  @keyframes blink {
      to {
          color: @red;
      }
  }

  #idle_inhibitor.deactivated {
    background-color: shade(@base, 1);
    color: @lavender;
  }

  #idle_inhibitor.activated {
      background-color: shade(@base, 1);
      color: @green;
  }

  #battery.critical:not(.charging) {
      color: @red;
      animation-name: blink;
      animation-duration: 0.5s;
      animation-timing-function: linear;
      animation-iteration-count: infinite;
      animation-direction: alternate;
  }

  #cpu {
      color: @blue;
  }

  #cpu #cpu-icon {
      color: @blue;
  }

  #memory {
      color: @flamingo;
  }

  #network {
      color: @lavender;
      border-radius: 10px;
      margin-right: 5px;
  }

  #network.disconnected {
      color: @red;
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

  #idle_inhibitor {
      background-color: @yellow;
      color: @base;
  }

  #tray {
      margin: 8px 10px;
      border-radius: 10px;
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
      margin-top: 6px;
      margin-left: 8px;
      margin-right: 8px;
      padding-left: 10px;
      padding-right: 5px;
      margin-bottom: 0px;
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
''
