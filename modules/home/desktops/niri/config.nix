{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.desktops.niri;
in
{
  config = mkIf cfg.enable {
    programs.niri.enable = true;
    programs.niri.settings = {
      outputs = mkMerge [
        {
          "*" = {
            scale = 1.0;
          };
        }
        cfg.outputs
      ];

      input = {
        keyboard.xkb = { };
        touchpad.tap = true;
        touchpad.natural-scroll = true;
        focus-follows-mouse.enable = true;
        workspace-auto-back-and-forth = true;
      };

      prefer-no-csd = true;

      hotkey-overlay.skip-at-startup = true;

      gestures.hot-corners.enable = false;

      layout = {
        default-column-width = {
          proportion = 0.5;
        };
        preset-column-widths = [
          { proportion = 0.25; }
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
          { proportion = 0.75; }
          { proportion = 1.0; }
        ];
      };

      workspaces = { };

      window-rules = [
        {
          clip-to-geometry = true;
          geometry-corner-radius = {
            bottom-left = 12.0;
            bottom-right = 12.0;
            top-left = 12.0;
            top-right = 12.0;
          };
        }
      ];

      layer-rules = [
        {
          matches = [
            {
              namespace = "^noctalia-overview.*";
            }
          ];
          place-within-backdrop = true;
        }
      ];

      spawn-at-startup = [
        { command = [ "xwayland-satellite" ]; }
      ]
      ++ (map (cmd: { command = cmd; }) cfg.extraStartupApps);
    };

    home.packages =
      with pkgs;
      [
        xwayland-satellite
      ]
      ++ cfg.extraPackages;
  };
}
