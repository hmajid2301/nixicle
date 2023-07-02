{ colorscheme }:
''
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
      color: white;
      background-color: @mauve;
      border-radius: 20px;
  }

  #workspaces button.active * {
      color: @base;
  }

  #mode {
      color: #ebcb8b;
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
      color: @sapphire;
      border-radius: 0 10px 10px 0;
      margin-right: 10px;
  }

  #battery.charging {
      color: @lavender;
  }

  @keyframes blink {
      to {
          color: @red;
      }
  }

  #battery.critical:not(.charging) {
      color: #bf616a;
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
      color: @maroon;
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
      color: @maroon;
  }

  #idle_inhibitor {
      background-color: #ebcb8b;
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
      color: #F28FAD;
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
