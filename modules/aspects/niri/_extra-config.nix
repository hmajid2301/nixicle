{ ... }:
''
  input {
      keyboard {
          xkb {
              layout "gb"
              model ""
              rules ""
              variant ""
          }
          repeat-delay 600
          repeat-rate 25
          track-layout "global"
      }
      touchpad {
          tap
          natural-scroll
      }
      focus-follows-mouse max-scroll-amount="0%"
      workspace-auto-back-and-forth
  }
  output "*" {
      scale 1.000000
      transform "normal"
  }
  screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"
  prefer-no-csd
  layout {
      gaps 8
      struts {
          left 0
          right 0
          top 0
          bottom 0
      }
      focus-ring { width 4; }
      border { off; }
      default-column-width { proportion 0.500000; }
      preset-column-widths {
          proportion 0.333330
          proportion 0.500000
          proportion 0.666670
          proportion 1.000000
      }
      center-focused-column "never"
      always-center-single-column
  }
  cursor {
      xcursor-theme "default"
      xcursor-size 24
  }
  hotkey-overlay { skip-at-startup; }
  binds {
      Mod+0 { focus-workspace 10; }
      Mod+1 { focus-workspace 1; }
      Mod+2 { focus-workspace 2; }
      Mod+3 { focus-workspace 3; }
      Mod+4 { focus-workspace 4; }
      Mod+5 { focus-workspace 5; }
      Mod+6 { focus-workspace 6; }
      Mod+7 { focus-workspace 7; }
      Mod+8 { focus-workspace 8; }
      Mod+9 { focus-workspace 9; }
      Mod+Alt+H { move-column-left; }
      Mod+Alt+J { move-window-down; }
      Mod+Alt+K { move-window-up; }
      Mod+Alt+L { move-column-right; }
      Mod+Alt+Shift+H { move-window-to-monitor-left; }
      Mod+Alt+Shift+J { move-window-to-monitor-down; }
      Mod+Alt+Shift+K { move-window-to-monitor-up; }
      Mod+Alt+Shift+L { move-window-to-monitor-right; }
      Mod+B { spawn "rofi" "-show" "drun"; }
      Mod+C { center-column; }
      Mod+Comma { spawn "noctalia-shell" "ipc" "call" "settings" "toggle"; }
      Mod+Ctrl+H { consume-or-expel-window-left; }
      Mod+Ctrl+J { focus-workspace-down; }
      Mod+Ctrl+K { focus-workspace-up; }
      Mod+Ctrl+L { consume-or-expel-window-right; }
      Mod+Ctrl+Shift+0 { move-column-to-workspace 10; }
      Mod+Ctrl+Shift+1 { move-column-to-workspace 1; }
      Mod+Ctrl+Shift+2 { move-column-to-workspace 2; }
      Mod+Ctrl+Shift+3 { move-column-to-workspace 3; }
      Mod+Ctrl+Shift+4 { move-column-to-workspace 4; }
      Mod+Ctrl+Shift+5 { move-column-to-workspace 5; }
      Mod+Ctrl+Shift+6 { move-column-to-workspace 6; }
      Mod+Ctrl+Shift+7 { move-column-to-workspace 7; }
      Mod+Ctrl+Shift+8 { move-column-to-workspace 8; }
      Mod+Ctrl+Shift+9 { move-column-to-workspace 9; }
      Mod+Ctrl+Shift+H { focus-monitor-left; }
      Mod+Ctrl+Shift+J { focus-monitor-down; }
      Mod+Ctrl+Shift+K { focus-monitor-up; }
      Mod+Ctrl+Shift+L { focus-monitor-right; }
      Mod+E { spawn "nautilus"; }
      Mod+Equal { set-column-width "+10%"; }
      Mod+Escape { spawn "noctalia-shell" "ipc" "call" "lockScreen" "lock"; }
      Mod+F { fullscreen-window; }
      Mod+H { focus-column-or-monitor-left; }
      Mod+J { focus-window-or-workspace-down; }
      Mod+K { focus-window-or-workspace-up; }
      Mod+L { focus-column-or-monitor-right; }
      Mod+M { maximize-column; }
      Mod+Minus { set-column-width "-10%"; }
      Mod+O { toggle-overview; }
      Mod+Print { spawn "niri" "msg" "action" "screenshot-window"; }
      Mod+Q { close-window; }
      Mod+R { switch-preset-column-width; }
      Mod+Return { spawn "ghostty"; }
      Mod+S { spawn "noctalia-shell" "ipc" "call" "controlCenter" "toggle"; }
      Mod+Shift+0 { move-window-to-workspace 10; }
      Mod+Shift+1 { move-window-to-workspace 1; }
      Mod+Shift+2 { move-window-to-workspace 2; }
      Mod+Shift+3 { move-window-to-workspace 3; }
      Mod+Shift+4 { move-window-to-workspace 4; }
      Mod+Shift+5 { move-window-to-workspace 5; }
      Mod+Shift+6 { move-window-to-workspace 6; }
      Mod+Shift+7 { move-window-to-workspace 7; }
      Mod+Shift+8 { move-window-to-workspace 8; }
      Mod+Shift+9 { move-window-to-workspace 9; }
      Mod+Shift+E { quit; }
      Mod+Shift+Equal { set-window-height "+10%"; }
      Mod+Shift+Escape { spawn "noctalia-shell" "ipc" "call" "sessionMenu" "toggle"; }
      Mod+Shift+F { spawn "nfsm-cli"; }
      Mod+Shift+H { move-column-to-monitor-left; }
      Mod+Shift+J { move-window-to-monitor-down; }
      Mod+Shift+K { move-window-to-monitor-up; }
      Mod+Shift+L { move-column-to-monitor-right; }
      Mod+Shift+Minus { set-window-height "-10%"; }
      Mod+Shift+R { switch-preset-column-width-back; }
      Mod+Space { spawn "noctalia-shell" "ipc" "call" "launcher" "toggle"; }
      Mod+T { toggle-window-floating; }
      Mod+V { spawn "noctalia-shell" "ipc" "call" "launcher" "clipboard"; }
      Mod+W { toggle-column-tabbed-display; }
      Print { spawn "niri" "msg" "action" "screenshot"; }
      Shift+Print { spawn "niri" "msg" "action" "screenshot-screen"; }
      XF86AudioLowerVolume { spawn "noctalia-shell" "ipc" "call" "volume" "decrease"; }
      XF86AudioMute { spawn "noctalia-shell" "ipc" "call" "volume" "muteOutput"; }
      XF86AudioRaiseVolume { spawn "noctalia-shell" "ipc" "call" "volume" "increase"; }
      XF86MonBrightnessDown { spawn "noctalia-shell" "ipc" "call" "brightness" "decrease"; }
      XF86MonBrightnessUp { spawn "noctalia-shell" "ipc" "call" "brightness" "increase"; }
  }
  spawn-at-startup "xwayland-satellite"
  spawn-at-startup "nfsm"
  spawn-at-startup "noctalia-shell"
  window-rule {
      geometry-corner-radius 10.000000 10.000000 10.000000 10.000000
      clip-to-geometry true
  }
  window-rule {
      match app-id="^google-chrome$" title=".*Meet.*"
      match app-id="^google-chrome$" title=".*meet\\.google\\.com.*"
      match app-id="^google-chrome$" title=".*Google Meet.*"
      match app-id="^google-chrome$" title=".*Zoom.*"
      match app-id="^google-chrome$" title=".*zoom\\.us.*"
      match app-id="^google-chrome$" title=".*Join Zoom Meeting.*"
      match app-id="^google-chrome$" title="^$"
      match app-id="^firefox$" title=".*PayPal.*"
      match app-id="^firefox$" title=".*popup.*"
      match app-id="^firefox$" title=".*Authentication.*"
      match app-id="^firefox$" title=".*Login.*"
      match app-id="^firefox$" title=".*Security.*"
      match app-id="^org.mozilla.firefox$" title=".*PayPal.*"
      match app-id="^org.mozilla.firefox$" title=".*popup.*"
      match app-id="^firefox$" title=".*Bitwarden.*"
      match app-id="^org.mozilla.firefox$" title=".*Bitwarden.*"
      match app-id="^firefox$" title=".*Extension.*Bitwarden.*"
      match app-id="^bitwarden$"
      match app-id="^com.bitwarden.desktop$"
      match app-id="^firefox$" title="^$"
      match app-id="^org.mozilla.firefox$" title="^$"
      default-column-width
      open-on-output ""
      open-maximized false
      open-fullscreen false
  }
  layer-rule {
      match namespace="^noctalia-overview.*"
      place-within-backdrop true
  }
  gestures { hot-corners { off; }; }
''
