{
  binds = {
    "Mod+0".focus-workspace = 10;
    "Mod+1".focus-workspace = 1;
    "Mod+2".focus-workspace = 2;
    "Mod+3".focus-workspace = 3;
    "Mod+4".focus-workspace = 4;
    "Mod+5".focus-workspace = 5;
    "Mod+6".focus-workspace = 6;
    "Mod+7".focus-workspace = 7;
    "Mod+8".focus-workspace = 8;
    "Mod+9".focus-workspace = 9;
    "Mod+Alt+H".move-column-left = { };
    "Mod+Alt+J".move-window-down = { };
    "Mod+Alt+K".move-window-up = { };
    "Mod+Alt+L".move-column-right = { };
    "Mod+Alt+Shift+H".move-window-to-monitor-left = { };
    "Mod+Alt+Shift+J".move-window-to-monitor-down = { };
    "Mod+Alt+Shift+K".move-window-to-monitor-up = { };
    "Mod+Alt+Shift+L".move-window-to-monitor-right = { };
    "Mod+B".spawn = [
      "rofi"
      "-show"
      "drun"
    ];
    "Mod+C".center-column = { };
    "Mod+Comma".spawn = [
      "noctalia"
      "msg"
      "settings-toggle"
    ];
    "Mod+Ctrl+H".consume-or-expel-window-left = { };
    "Mod+Ctrl+J".focus-workspace-down = { };
    "Mod+Ctrl+K".focus-workspace-up = { };
    "Mod+Ctrl+L".consume-or-expel-window-right = { };
    "Mod+Ctrl+Shift+0".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 10 ];
    };
    "Mod+Ctrl+Shift+1".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 1 ];
    };
    "Mod+Ctrl+Shift+2".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 2 ];
    };
    "Mod+Ctrl+Shift+3".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 3 ];
    };
    "Mod+Ctrl+Shift+4".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 4 ];
    };
    "Mod+Ctrl+Shift+5".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 5 ];
    };
    "Mod+Ctrl+Shift+6".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 6 ];
    };
    "Mod+Ctrl+Shift+7".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 7 ];
    };
    "Mod+Ctrl+Shift+8".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 8 ];
    };
    "Mod+Ctrl+Shift+9".move-column-to-workspace = {
      _props.focus = false;
      _args = [ 9 ];
    };
    "Mod+Ctrl+Shift+H".focus-monitor-left = { };
    "Mod+Ctrl+Shift+J".focus-monitor-down = { };
    "Mod+Ctrl+Shift+K".focus-monitor-up = { };
    "Mod+Ctrl+Shift+L".focus-monitor-right = { };
    "Mod+E".spawn = [ "nautilus" ];
    "Mod+Equal".set-column-width = "+10%";
    "Mod+Escape".spawn = [
      "noctalia"
      "msg"
      "session"
      "lock"
    ];
    "Mod+F".fullscreen-window = { };
    "Mod+H".focus-column-or-monitor-left = { };
    "Mod+J".focus-window-or-workspace-down = { };
    "Mod+K".focus-window-or-workspace-up = { };
    "Mod+L".focus-column-or-monitor-right = { };
    "Mod+M".maximize-column = { };
    "Mod+Minus".set-column-width = "-10%";
    "Mod+O".toggle-overview = { };
    "Mod+Print".spawn = [
      "niri"
      "msg"
      "action"
      "screenshot-window"
    ];
    "Mod+Q".close-window = { };
    "Mod+R".switch-preset-column-width = { };
    "Mod+Return".spawn = [
      "ghostty"
      "+new-window"
    ];
    "Mod+S".spawn = [
      "noctalia"
      "msg"
      "panel-toggle"
      "control-center"
    ];
    "Mod+Shift+0".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 10 ];
    };
    "Mod+Shift+1".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 1 ];
    };
    "Mod+Shift+2".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 2 ];
    };
    "Mod+Shift+3".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 3 ];
    };
    "Mod+Shift+4".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 4 ];
    };
    "Mod+Shift+5".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 5 ];
    };
    "Mod+Shift+6".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 6 ];
    };
    "Mod+Shift+7".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 7 ];
    };
    "Mod+Shift+8".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 8 ];
    };
    "Mod+Shift+9".move-window-to-workspace = {
      _props.focus = false;
      _args = [ 9 ];
    };
    "Mod+Shift+E".quit = { };
    "Mod+Shift+Equal".set-window-height = "+10%";
    "Mod+Shift+Escape".spawn = [
      "noctalia"
      "msg"
      "panel-toggle"
      "session"
    ];
    "Mod+Shift+F".spawn = [ "nfsm-cli" ];
    "Mod+Shift+H".move-column-to-monitor-left = { };
    "Mod+Shift+J".move-window-to-monitor-down = { };
    "Mod+Shift+K".move-window-to-monitor-up = { };
    "Mod+Shift+L".move-column-to-monitor-right = { };
    "Mod+Shift+Minus".set-window-height = "-10%";
    "Mod+Shift+R".switch-preset-column-width-back = { };
    "Mod+Space".spawn = [
      "noctalia"
      "msg"
      "panel-toggle"
      "launcher"
    ];
    "Mod+T".toggle-window-floating = { };
    "Mod+V".spawn = [
      "noctalia"
      "msg"
      "panel-toggle"
      "clipboard"
    ];
    "Mod+W".toggle-column-tabbed-display = { };
    Print.spawn = [
      "niri"
      "msg"
      "action"
      "screenshot"
    ];
    "Shift+Print".spawn = [
      "niri"
      "msg"
      "action"
      "screenshot-screen"
    ];
    XF86AudioLowerVolume.spawn = [
      "noctalia"
      "msg"
      "volume-down"
    ];
    XF86AudioMute.spawn = [
      "noctalia"
      "msg"
      "volume-mute"
    ];
    XF86AudioRaiseVolume.spawn = [
      "noctalia"
      "msg"
      "volume-up"
    ];
    XF86MonBrightnessDown.spawn = [
      "noctalia"
      "msg"
      "brightness-down"
    ];
    XF86MonBrightnessUp.spawn = [
      "noctalia"
      "msg"
      "brightness-up"
    ];
  };
}
