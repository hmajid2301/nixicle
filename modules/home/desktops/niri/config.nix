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
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "95%";
        };
        workspace-auto-back-and-forth = true;
      };

      prefer-no-csd = true;

      hotkey-overlay.skip-at-startup = true;

      gestures.hot-corners.enable = false;

      layout = {
        gaps = 8;
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
            bottom-left = 10.0;
            bottom-right = 10.0;
            top-left = 10.0;
            top-right = 10.0;
          };
        }
        {
          matches = [
            {
              app-id = "^google-chrome$";
              title = ".*Meet.*";
            }
            {
              app-id = "^google-chrome$";
              title = ".*meet\\.google\\.com.*";
            }
            {
              app-id = "^google-chrome$";
              title = ".*Google Meet.*";
            }
          ];
          default-column-width = { };
          open-on-output = "";
          open-maximized = false;
          open-fullscreen = false;
        }
        {
          matches = [
            {
              app-id = "^google-chrome$";
              title = ".*Zoom.*";
            }
            {
              app-id = "^google-chrome$";
              title = ".*zoom\\.us.*";
            }
            {
              app-id = "^google-chrome$";
              title = ".*Join Zoom Meeting.*";
            }
          ];
          default-column-width = { };
          open-on-output = "";
          open-maximized = false;
          open-fullscreen = false;
        }
        {
          matches = [
            {
              app-id = "^google-chrome$";
              title = "^$";
            }
          ];
          default-column-width = { };
          open-on-output = "";
          open-maximized = false;
          open-fullscreen = false;
        }
        {
          matches = [
            {
              app-id = "^firefox$";
              title = ".*PayPal.*";
            }
            {
              app-id = "^firefox$";
              title = ".*popup.*";
            }
            {
              app-id = "^firefox$";
              title = ".*Authentication.*";
            }
            {
              app-id = "^firefox$";
              title = ".*Login.*";
            }
            {
              app-id = "^firefox$";
              title = ".*Security.*";
            }
            {
              app-id = "^org.mozilla.firefox$";
              title = ".*PayPal.*";
            }
            {
              app-id = "^org.mozilla.firefox$";
              title = ".*popup.*";
            }
          ];
          default-column-width = { };
          open-on-output = "";
          open-maximized = false;
          open-fullscreen = false;
        }
        {
          matches = [
            {
              app-id = "^firefox$";
              title = ".*Bitwarden.*";
            }
            {
              app-id = "^org.mozilla.firefox$";
              title = ".*Bitwarden.*";
            }
            {
              app-id = "^firefox$";
              title = ".*Extension.*Bitwarden.*";
            }
            {
              app-id = "^bitwarden$";
            }
            {
              app-id = "^com.bitwarden.desktop$";
            }
          ];
          default-column-width = { };
          open-on-output = "";
          open-maximized = false;
          open-fullscreen = false;
        }
        {
          matches = [
            {
              app-id = "^firefox$";
              title = "^$";
            }
            {
              app-id = "^org.mozilla.firefox$";
              title = "^$";
            }
          ];
          default-column-width = { };
          open-on-output = "";
          open-maximized = false;
          open-fullscreen = false;
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
