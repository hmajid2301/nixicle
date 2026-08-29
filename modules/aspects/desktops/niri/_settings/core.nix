{ lib, ... }:
{
  input = {
    keyboard = {
      xkb = {
        layout = "gb";
        model = "";
        rules = "";
        variant = "";
      };
      repeat-delay = 600;
      repeat-rate = 25;
      track-layout = "global";
    };
    touchpad = {
      tap = { };
      natural-scroll = { };
    };
    focus-follows-mouse._props.max-scroll-amount = "0%";
    workspace-auto-back-and-forth = { };
  };

  _children = lib.mkAfter [
    {
      output = {
        _args = [ "eDP-1" ];
        scale = 1.0;
        transform = "normal";
      };
    }
    {
      output = {
        _args = [ "DP-1" ];
        scale = 1.0;
        transform = "normal";
      };
    }
    {
      output = {
        _args = [ "DP-2" ];
        scale = 1.0;
        transform = "normal";
      };
    }
    {
      output = {
        _args = [ "HDMI-A-1" ];
        scale = 1.0;
        transform = "normal";
      };
    }
    {
      output = {
        _args = [ "HDMI-A-2" ];
        scale = 1.0;
        transform = "normal";
      };
    }
  ];

  screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
  prefer-no-csd = { };

  layout = {
    gaps = 8;
    struts = {
      left = 0;
      right = 0;
      top = 0;
      bottom = 0;
    };
    focus-ring.width = 4;
    border.off = { };
    default-column-width.proportion = 0.5;
    preset-column-widths._children = [
      { proportion = 0.33333; }
      { proportion = 0.5; }
      { proportion = 0.66667; }
      { proportion = 1.0; }
    ];
    center-focused-column = "never";
    always-center-single-column = { };
  };

  cursor = {
    xcursor-theme = "default";
    xcursor-size = 24;
  };

  hotkey-overlay.skip-at-startup = { };
}
