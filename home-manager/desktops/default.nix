{ inputs
, config
, pkgs
, ...
}: {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./wayland
  ];

  home.packages = [
    inputs.hypr-contrib.packages.${pkgs.system}.grimblast
    inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";

      "$notifycmd" = "notify-send -h string:x-canonical-private-synchronous:hypr-cfg -u low";

      decoration = {
        rounding = 5;
      };

      input = {
        kb_layout = "gb";
        touchpad = {
          disable_while_typing = false;
        };
      };

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 3;
        "col.active_border" = "0xff${config.colorscheme.colors.base07}";
        "col.inactive_border" = "0xff${config.colorscheme.colors.base02}";
        "col.group_border_active" = "0xff${config.colorscheme.colors.base0B}";
        "col.group_border" = "0xff${config.colorscheme.colors.base04}";
      };

      exec-once = [
        "mako &"
        "kanshi &"
        "sway-audio-idle-inhibit &"
        "waybar &"
        "gammastep-indicator &"
        "swaybg -i ${config.wallpaper} --mode fill &"
      ];

      windowrulev2 = [
        # Ignore default rules
        "fullscreen, title:^(Steam)$"
        "fullscreen, title:^(Guild Wars 2)$"
        "idleinhibit focus, class:^(mpv)$"
        "idleinhibit fullscreen, class:^(firefox)"
      ];

      bind = [
        # scripts
        "CONTROL_ALT,DELETE,exec,~/dotfiles/home-manager/desktops/wayland/scripts/power_menu.sh"
        "$mod, w, exec, makoctl dismiss"

        # change mode
        "$mod, F, fullscreen, 0"
        "$mod, F, exec, $notifycmd 'Fullscreen Mode'"
        "$mod, S, pseudo,"
        "$mod, S, exec, $notifycmd 'Pseudo Mode'"
        "$mod, Space, togglefloating,"
        "$mod, Space, centerwindow,"

        # move to workspace
        "$mod,1,workspace,01"
        "$mod,2,workspace,02"
        "$mod,3,workspace,03"
        "$mod,4,workspace,04"
        "$mod,5,workspace,05"
        "$mod,6,workspace,06"
        "$mod,7,workspace,07"
        "$mod,8,workspace,08"
        "$mod,9,workspace,09"
        "$mod,0,workspace,10"

        # move window to workspace (without changing)
        "SUPERSHIFT,1,movetoworkspacesilent,01"
        "SUPERSHIFT,2,movetoworkspacesilent,02"
        "SUPERSHIFT,3,movetoworkspacesilent,03"
        "SUPERSHIFT,4,movetoworkspacesilent,04"
        "SUPERSHIFT,5,movetoworkspacesilent,05"
        "SUPERSHIFT,6,movetoworkspacesilent,06"
        "SUPERSHIFT,7,movetoworkspacesilent,07"
        "SUPERSHIFT,8,movetoworkspacesilent,08"
        "SUPERSHIFT,9,movetoworkspacesilent,09"
        "SUPERSHIFT,0,movetoworkspacesilent,10"

        # swap windows
        "SUPERSHIFT,h,swapwindow,l"
        "SUPERSHIFT,l,swapwindow,r"
        "SUPERSHIFT,k,swapwindow,u"
        "SUPERSHIFT,j,swapwindow,d"

        # move window
        "ALTCTRL,l,movewindow,r"
        "ALTCTRL,h,movewindow,l"
        "ALTCTRL,k,movewindow,u"
        "ALTCTRL,j,movewindow,d"

        # focus
        "$mod,h,movefocus,l"
        "$mod,l,movefocus,r"
        "$mod,k,movefocus,u"
        "$mod,j,movefocus,d"

        # focus monitor
        "SUPERCONTROL,h,focusmonitor,l"
        "SUPERCONTROL,l,focusmonitor,r"
        "SUPERCONTROL,k,focusmonitor,u"
        "SUPERCONTROL,j,focusmonitor,d"

        # move window to monitor
        "SUPERALT,h,movecurrentworkspacetomonitor,l"
        "SUPERALT,l,movecurrentworkspacetomonitor,r"
        "SUPERALT,k,movecurrentworkspacetomonitor,u"
        "SUPERALT,j,movecurrentworkspacetomonitor,d"

        # screenshot
        ",Print,exec,grimblast --notify copysave area"
        "SHIFT,Print,exec,grimblast --notify copy active"
        "CONTROL,Print,exec,grimblast --notify copy screen"
        "SUPER,Print,exec,grimblast --notify copy window"
        "ALT,Print,exec,grimblast --notify copy area"
        "SUPER,bracketleft,exec,grimblast --notify --cursor copysave area ~/Pictures/$(date \"+%Y-%m-%d\" T \"%H:%M:%S_no_watermark\").png"
        "SUPER,bracketright,exec, grimblast --notify --cursor copy area"

        # keyboard controls
        ",XF86MonBrightnessUp,exec, ~/dotfiles/home-manager/desktops/wayland/scripts/brightness.sh --inc"
        ",XF86MonBrightnessDown,exec, ~/dotfiles/home-manager/desktops/wayland/scripts/brightness.sh --dec"
        ",XF86AudioRaiseVolume,exec, ~/dotfiles/home-manager/desktops/wayland/scripts/volume.sh --inc"
        ",XF86AudioLowerVolume,exec, ~/dotfiles/home-manager/desktops/wayland/scripts/volume.sh --dec"
        ",XF86AudioMute,exec, ~/dotfiles/home-manager/desktops/wayland/scripts/volume.sh --toggle"
        ",XF86AudioMicMute,exec, ~/dotfiles/home-manager/desktops/wayland/scripts/volume.sh --toggle-mic"
        ",XF86AudioNext,exec,playerctl next"
        ",XF86AudioPrev,exec,playerctl previous"
        ",XF86AudioPlay,exec,playerctl play-pause"
        ",XF86AudioStop,exec,playerctl stop"
        "ALT,XF86AudioNext,exec,playerctld shift"
        "ALT,XF86AudioPrev,exec,playerctld unshift"
        "ALT,XF86AudioPlay,exec,systemctl --user restart playerctld"

        # scratch pad
        "$mod,u,togglespecialworkspace"
        "SUPERSHIFT,u,movetoworkspace,special"
      ];

      bindl = [
        ",switch:Lid Switch, exec, ~/dotfiles/home-manager/desktops/wayland/scripts/laptop_lid_switch.sh"
      ];

      bindm = [
        # main shortcuts
        "$mod, Return, exec, ${config.home.sessionVariables.TERMINAL}"
        "$mod, b, exec, ${config.home.sessionVariables.browser}"
        "$mod, a, exec, ${pkgs.rofi}/bin/rofi -show drun -modi drun"
        "$mod, q, exec, killactive"

        # Lock screen
        "XF86Launch5, exec, swaylock -S"
        "XF86Launch4, exec, swaylock -S"
        "$mod, backspace, exec, swaylock -S"

        # mouse movements
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
        "$mod ALT, mouse:272, resizewindow"
      ];

      binde = [
        "SUPERALT, h, resizeactive, -20 0"
        "SUPERALT, l, resizeactive, 20 0"
        "SUPERALT, k, resizeactive, 0 -20"
        "SUPERALT, j, resizeactive, 0 20"
      ];
    };
  };
}
