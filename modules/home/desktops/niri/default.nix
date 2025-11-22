{
  config,
  lib,
  pkgs,
  mkOpt ? null,
  mkBoolOpt ? null,
  ...
}:
with lib;
with types;
let
  cfg = config.desktops.niri;

  noctalia =
    cmd:
    [
      "qs"
      "-c"
      "noctalia-shell"
      "ipc"
      "call"
    ]
    ++ (pkgs.lib.splitString " " cmd);
in
{
  options.desktops.niri = {
    enable = mkEnableOption "Enable niri window manager";

    extraPackages = mkOpt (listOf package) [ ] "Extra packages to install for niri";
  };

  config = mkIf cfg.enable {
    programs.niri.enable = true;
    stylix.targets.niri.enable = lib.mkDefault true;

    programs.niri.settings = {
      input = {
        keyboard.xkb = { };
        touchpad.tap = true;
        touchpad.natural-scroll = true;
        focus-follows-mouse.enable = true;
        workspace-auto-back-and-forth = true;
      };

      prefer-no-csd = true;

      hotkey-overlay.skip-at-startup = true;

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

      spawn-at-startup = [ { command = [ "xwayland-satellite" ]; } ];

      binds = with config.lib.niri.actions; {
        "Mod+Return".action.spawn = [ "ghostty" ];
        "Mod+E".action.spawn = [ "thunar" ];

        "Mod+Space".action.spawn = noctalia "launcher toggle";
        "Mod+S".action.spawn = noctalia "controlCenter toggle";
        "Mod+Comma".action.spawn = noctalia "settings toggle";
        "Mod+V".action.spawn = noctalia "launcher clipboard";
        "Mod+C".action.spawn = noctalia "launcher calculator";

        "Mod+Q".action = close-window;
        "Mod+F".action = fullscreen-window;
        "Mod+T".action = toggle-window-floating;
        "Mod+O".action = toggle-overview;

        "Mod+H".action = focus-column-left;
        "Mod+L".action = focus-column-right;
        "Mod+J".action = focus-window-down;
        "Mod+K".action = focus-window-up;

        "Mod+Shift+H".action = move-column-left;
        "Mod+Shift+L".action = move-column-right;
        "Mod+Shift+J".action = move-window-down;
        "Mod+Shift+K".action = move-window-up;

        "Mod+Ctrl+H".action = focus-monitor-left;
        "Mod+Ctrl+L".action = focus-monitor-right;
        "Mod+Ctrl+J".action = focus-monitor-down;
        "Mod+Ctrl+K".action = focus-monitor-up;

        "Mod+1".action.focus-workspace = 1;
        "Mod+2".action.focus-workspace = 2;
        "Mod+3".action.focus-workspace = 3;
        "Mod+4".action.focus-workspace = 4;
        "Mod+5".action.focus-workspace = 5;
        "Mod+6".action.focus-workspace = 6;
        "Mod+7".action.focus-workspace = 7;
        "Mod+8".action.focus-workspace = 8;
        "Mod+9".action.focus-workspace = 9;
        "Mod+0".action.focus-workspace = 10;

        "Mod+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Shift+9".action.move-column-to-workspace = 9;
        "Mod+Shift+0".action.move-column-to-workspace = 10;

        "Print".action.spawn = [
          "grimblast"
          "--notify"
          "copysave"
          "area"
        ];

        "XF86AudioRaiseVolume".action.spawn = noctalia "volume increase";
        "XF86AudioLowerVolume".action.spawn = noctalia "volume decrease";
        "XF86AudioMute".action.spawn = noctalia "volume muteOutput";

        "XF86MonBrightnessUp".action.spawn = noctalia "brightness increase";
        "XF86MonBrightnessDown".action.spawn = noctalia "brightness decrease";

        "Mod+Escape".action.spawn = noctalia "lockScreen lock";
        "Mod+Shift+Escape".action.spawn = noctalia "sessionMenu toggle";

        "Mod+Shift+E".action = quit;
      };
    };

    home.packages = with pkgs; [ xwayland-satellite ] ++ cfg.extraPackages;
  };
}
