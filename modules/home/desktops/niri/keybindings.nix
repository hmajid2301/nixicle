{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.desktops.niri;

  noctalia =
    cmd:
    [
      "noctalia-shell"
      "ipc"
      "call"
    ]
    ++ (pkgs.lib.splitString " " cmd);
in
{
  config = mkIf cfg.enable {
    programs.niri.settings = {
      binds = with config.lib.niri.actions; {
        "Mod+Return".action.spawn = [ "ghostty" ];
        "Mod+E".action.spawn = [ "nautilus" ];

        "Mod+Space".action.spawn = noctalia "launcher toggle";
        "Mod+B".action.spawn = [
          "rofi"
          "-show"
          "drun"
        ];
        "Mod+S".action.spawn = noctalia "controlCenter toggle";
        "Mod+Comma".action.spawn = noctalia "settings toggle";
        "Mod+V".action.spawn = noctalia "launcher clipboard";

        "Mod+Q".action = close-window;
        "Mod+F".action.spawn = "nfsm-cli";
        "Mod+T".action = toggle-window-floating;
        "Mod+O".action = toggle-overview;
        "Mod+C".action = center-column;
        "Mod+M".action = maximize-column;

        "Mod+H".action = focus-column-or-monitor-left;
        "Mod+L".action = focus-column-or-monitor-right;
        "Mod+J".action = focus-window-or-workspace-down;
        "Mod+K".action = focus-window-or-workspace-up;

        # Navigate workspaces63 sequentially
        "Mod+Ctrl+J".action = focus-workspace-down;
        "Mod+Ctrl+K".action = focus-workspace-up;

        # Smart movement: move within monitor, then to adjacent monitor when at edge
        "Mod+Shift+H".action = move-column-to-monitor-left;
        "Mod+Shift+L".action = move-column-to-monitor-right;
        "Mod+Shift+J".action = move-window-to-monitor-down;
        "Mod+Shift+K".action = move-window-to-monitor-up;

        # Move windows into/out of columns
        "Mod+Ctrl+H".action = consume-or-expel-window-left;
        "Mod+Ctrl+L".action = consume-or-expel-window-right;

        "Mod+R".action = switch-preset-column-width;
        "Mod+Shift+R".action = switch-preset-column-width-back;

        # Adjust column width incrementally
        "Mod+Equal".action.set-column-width = "+10%";
        "Mod+Minus".action.set-column-width = "-10%";

        # Adjust window height incrementally
        "Mod+Shift+Equal".action.set-window-height = "+10%";
        "Mod+Shift+Minus".action.set-window-height = "-10%";

        # Focus monitors
        "Mod+Ctrl+Shift+H".action = focus-monitor-left;
        "Mod+Ctrl+Shift+L".action = focus-monitor-right;
        "Mod+Ctrl+Shift+J".action = focus-monitor-down;
        "Mod+Ctrl+Shift+K".action = focus-monitor-up;

        # Direct monitor movement (force move to specific monitor)
        "Mod+Alt+Shift+H".action = move-window-to-monitor-left;
        "Mod+Alt+Shift+L".action = move-window-to-monitor-right;
        "Mod+Alt+Shift+J".action = move-window-to-monitor-down;
        "Mod+Alt+Shift+K".action = move-window-to-monitor-up;

        # Local movement only (within current monitor/workspace)
        "Mod+Alt+H".action = move-column-left;
        "Mod+Alt+L".action = move-column-right;
        "Mod+Alt+J".action = move-window-down;
        "Mod+Alt+K".action = move-window-up;

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

        # Move only window to workspace (not whole column)
        "Mod+Shift+1".action.move-window-to-workspace = 1;
        "Mod+Shift+2".action.move-window-to-workspace = 2;
        "Mod+Shift+3".action.move-window-to-workspace = 3;
        "Mod+Shift+4".action.move-window-to-workspace = 4;
        "Mod+Shift+5".action.move-window-to-workspace = 5;
        "Mod+Shift+6".action.move-window-to-workspace = 6;
        "Mod+Shift+7".action.move-window-to-workspace = 7;
        "Mod+Shift+8".action.move-window-to-workspace = 8;
        "Mod+Shift+9".action.move-window-to-workspace = 9;
        "Mod+Shift+0".action.move-window-to-workspace = 10;

        # Move whole column to workspace
        "Mod+Ctrl+Shift+1".action.move-column-to-workspace = 1;
        "Mod+Ctrl+Shift+2".action.move-column-to-workspace = 2;
        "Mod+Ctrl+Shift+3".action.move-column-to-workspace = 3;
        "Mod+Ctrl+Shift+4".action.move-column-to-workspace = 4;
        "Mod+Ctrl+Shift+5".action.move-column-to-workspace = 5;
        "Mod+Ctrl+Shift+6".action.move-column-to-workspace = 6;
        "Mod+Ctrl+Shift+7".action.move-column-to-workspace = 7;
        "Mod+Ctrl+Shift+8".action.move-column-to-workspace = 8;
        "Mod+Ctrl+Shift+9".action.move-column-to-workspace = 9;
        "Mod+Ctrl+Shift+0".action.move-column-to-workspace = 10;

        # Use niri's built-in screenshot UI (select area interactively)
        "Print".action.spawn = [
          "niri"
          "msg"
          "action"
          "screenshot"
        ];
        "Shift+Print".action.spawn = [
          "niri"
          "msg"
          "action"
          "screenshot-screen"
        ];
        "Mod+Print".action.spawn = [
          "niri"
          "msg"
          "action"
          "screenshot-window"
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
  };
}
