{ inputs
, config
, pkgs
, ...
}: {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./common
  ];

  home.packages = [
    inputs.hypr-contrib.packages.${pkgs.system}.grimblast
    inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
  ];

  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    # TODO: move to https://github.com/spikespaz/hyprland-nix
    extraConfig = ''
      # ASCII Art from https://fsymbols.com/generators/carty/
      input {
      	kb_layout = gb
      	touchpad {
      		disable_while_typing=false
      	}
      }

      general {
      	gaps_in = 3
      	gaps_out = 5
      	border_size = 3
      	col.active_border=0xff${config.colorscheme.colors.base07}
      	col.inactive_border=0xff${config.colorscheme.colors.base02}
      }

      decoration {
      	rounding=5
      }

      misc {
       vrr = 2
       disable_hyprland_logo = 1;
       #disable_hypr_chan = 1
      }

      $notifycmd = notify-send -h string:x-canonical-private-synchronous:hypr-cfg -u low

      # █▀ █░█ █▀█ █▀█ ▀█▀ █▀▀ █░█ ▀█▀ █▀
      # ▄█ █▀█ █▄█ █▀▄ ░█░ █▄▄ █▄█ ░█░ ▄█
      bind = SUPER, Return, exec, ${config.my.settings.default.terminal}
      bind = SUPER, b, exec, ${config.my.settings.default.browser}
      bind = SUPER_SHIFT, f, exec, thunar
      bind = SUPER, a, exec, rofi -show drun -modi drun
      bind = ALT, Tab, exec, rofi -show window
      bind = SUPER, w, exec, makoctl dismiss

      # █▀▀ ▀▄▀ █▀▀ █▀▀ █▀█ ▀█▀ █ █▀█ █▄░█ █▀
      # ██▄ █░█ █▄▄ ██▄ █▀▀ ░█░ █ █▄█ █░▀█ ▄█
      windowrule = fullscreen, title:^(Guild Wars 2)$
      windowrulev2 = idleinhibit focus, class:^(mpv)$
      windowrulev2 = idleinhibit fullscreen, class:^(firefox)$

      # ▄▀█ █░█ ▀█▀ █▀█   █▀ ▀█▀ ▄▀█ █▀█ ▀█▀
      # █▀█ █▄█ ░█░ █▄█   ▄█ ░█░ █▀█ █▀▄ ░█░
      exec-once = mako &
      exec-once = kanshi &
      exec-once = sway-audio-idle-inhibit -w &
      exec-once = waybar &
      exec-once = gammastep-indicator &
      exec-once = mullvad-gui &
      exec-once = swaybg -i ${config.my.settings.wallpaper} --mode fill &

      # █▀ █▀▀ █▀█ █ █▀█ ▀█▀ █▀
      # ▄█ █▄▄ █▀▄ █ █▀▀ ░█░ ▄█
      bindl=,switch:Lid Switch, exec, ~/dotfiles/home-manager/desktops/wms/common/scripts/laptop_lid_switch.sh

      # █░░ █▀█ █▀▀ █▄▀   █▀ █▀▀ █▀█ █▀▀ █▀▀ █▄░█
      # █▄▄ █▄█ █▄▄ █░█   ▄█ █▄▄ █▀▄ ██▄ ██▄ █░▀█
      bind=,XF86Launch5,exec,swaylock -S
      bind=,XF86Launch4,exec,swaylock -S
      bind=SUPER,backspace,exec,swaylock -S

      # █▀ █▀▀ █▀█ ▄▀█ ▀█▀ █▀▀ █░█ █▀█ ▄▀█ █▀▄
      # ▄█ █▄▄ █▀▄ █▀█ ░█░ █▄▄ █▀█ █▀▀ █▀█ █▄▀
      bind=SUPER,u,togglespecialworkspace
      bind=SUPERSHIFT,u,movetoworkspace,special

      # █▀ █▀▀ █▀█ █▀▀ █▀▀ █▄░█ █▀ █░█ █▀█ ▀█▀
      # ▄█ █▄▄ █▀▄ ██▄ ██▄ █░▀█ ▄█ █▀█ █▄█ ░█░
      bind=,Print,exec,grimblast --notify copysave area
      bind=SHIFT,Print,exec,grimblast --notify copy active
      bind=CONTROL,Print,exec,grimblast --notify copy screen
      bind=SUPER,Print,exec,grimblast --notify copy window
      bind=ALT,Print,exec,grimblast --notify copy area
      bind=SUPER,bracketleft,exec,grimblast --notify --cursor copysave area ~/Pictures/$(date "+%Y-%m-%d"T"%H:%M:%S_no_watermark").png
      bind=SUPER,bracketright,exec, grimblast --notify --cursor copy area

      # █▄▀ █▀▀ █▄█ █▄▄ █▀█ ▄▀█ █▀█ █▀▄   █▀▀ █▀█ █▄░█ ▀█▀ █▀█ █▀█ █░░ █▀
      # █░█ ██▄ ░█░ █▄█ █▄█ █▀█ █▀▄ █▄▀   █▄▄ █▄█ █░▀█ ░█░ █▀▄ █▄█ █▄▄ ▄█
      bind=,XF86MonBrightnessUp,exec, ~/dotfiles/home-manager/desktops/wms/common/scripts/brightness.sh --inc
      bind=,XF86MonBrightnessDown,exec, ~/dotfiles/home-manager/desktops/wms/common/scripts/brightness.sh --dec
      bind=,XF86AudioRaiseVolume,exec, ~/dotfiles/home-manager/desktops/wms/common/scripts/volume.sh --inc
      bind=,XF86AudioLowerVolume,exec, ~/dotfiles/home-manager/desktops/wms/common/scripts/volume.sh --dec
      bind=,XF86AudioMute,exec, ~/dotfiles/home-manager/desktops/wms/common/scripts/volume.sh --toggle
      bind=,XF86AudioMicMute,exec, ~/dotfiles/home-manager/desktops/wms/common/scripts/volume.sh --toggle-mic
      bind=,XF86AudioNext,exec,playerctl next
      bind=,XF86AudioPrev,exec,playerctl previous
      bind=,XF86AudioPlay,exec,playerctl play-pause
      bind=,XF86AudioStop,exec,playerctl stop
      bind=ALT,XF86AudioNext,exec,playerctld shift
      bind=ALT,XF86AudioPrev,exec,playerctld unshift
      bind=ALT,XF86AudioPlay,exec,systemctl --user restart playerctld

      # █▀▀ █▀█ █▀▀ █░█ █▀
      # █▀░ █▄█ █▄▄ █▄█ ▄█
      bind=SUPER,h,movefocus,l
      bind=SUPER,l,movefocus,r
      bind=SUPER,k,movefocus,u
      bind=SUPER,j,movefocus,d

      # █▀ █░█░█ ▄▀█ █▀█   █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█ █▀
      # ▄█ ▀▄▀▄▀ █▀█ █▀▀   ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀ ▄█
      bind=SUPERSHIFT,h,swapwindow,l
      bind=SUPERSHIFT,l,swapwindow,r
      bind=SUPERSHIFT,k,swapwindow,u
      bind=SUPERSHIFT,j,swapwindow,d

      # █▀▀ █▀█ █▀▀ █░█ █▀   █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█
      # █▀░ █▄█ █▄▄ █▄█ ▄█   █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄
      bind=SUPERCONTROL,h,focusmonitor,l
      bind=SUPERCONTROL,l,focusmonitor,r
      bind=SUPERCONTROL,k,focusmonitor,u
      bind=SUPERCONTROL,j,focusmonitor,d

      # █▀▄▀█ █▀█ █░█ █▀▀   ▀█▀ █▀█   █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█
      # █░▀░█ █▄█ ▀▄▀ ██▄   ░█░ █▄█   █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄
      bind=SUPERALT,h,movecurrentworkspacetomonitor,l
      bind=SUPERALT,l,movecurrentworkspacetomonitor,r
      bind=SUPERALT,k,movecurrentworkspacetomonitor,u
      bind=SUPERALT,j,movecurrentworkspacetomonitor,d

      # █▀▀ █░█ ▄▀█ █▄░█ █▀▀ █▀▀   █░█░█ █▀█ █▀█ █▄▀ █▀ █▀█ ▄▀█ █▀▀ █▀▀
      # █▄▄ █▀█ █▀█ █░▀█ █▄█ ██▄   ▀▄▀▄▀ █▄█ █▀▄ █░█ ▄█ █▀▀ █▀█ █▄▄ ██▄
      bind=SUPER,1,workspace,01
      bind=SUPER,2,workspace,02
      bind=SUPER,3,workspace,03
      bind=SUPER,4,workspace,04
      bind=SUPER,5,workspace,05
      bind=SUPER,6,workspace,06
      bind=SUPER,7,workspace,07
      bind=SUPER,8,workspace,08
      bind=SUPER,9,workspace,09
      bind=SUPER,0,workspace,10

      # █▀▄▀█ █▀█ █░█ █▀▀   ▀█▀ █▀█   █░█░█ █▀█ █▀█ █▄▀ █▀ █▀█ ▄▀█ █▀▀ █▀▀
      # █░▀░█ █▄█ ▀▄▀ ██▄   ░█░ █▄█   ▀▄▀▄▀ █▄█ █▀▄ █░█ ▄█ █▀▀ █▀█ █▄▄ ██▄
      bind=SUPERSHIFT,1,movetoworkspacesilent,01
      bind=SUPERSHIFT,2,movetoworkspacesilent,02
      bind=SUPERSHIFT,3,movetoworkspacesilent,03
      bind=SUPERSHIFT,4,movetoworkspacesilent,04
      bind=SUPERSHIFT,5,movetoworkspacesilent,05
      bind=SUPERSHIFT,6,movetoworkspacesilent,06
      bind=SUPERSHIFT,7,movetoworkspacesilent,07
      bind=SUPERSHIFT,8,movetoworkspacesilent,08
      bind=SUPERSHIFT,9,movetoworkspacesilent,09
      bind=SUPERSHIFT,0,movetoworkspacesilent,10

      bind=ALTCTRL,L,movewindow,r
      bind=ALTCTRL,H,movewindow,l
      bind=ALTCTRL,K,movewindow,u
      bind=ALTCTRL,J,movewindow,d

      # █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀▄▀█ ▄▀█ █▄░█ ▄▀█ █▀▀ █▀▄▀█ █▀▀ █▄░█ ▀█▀
      # ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █░▀░█ █▀█ █░▀█ █▀█ █▄█ █░▀░█ ██▄ █░▀█ ░█░
      bind = SUPER, Q, killactive,
      bind = SUPER, F,      fullscreen, 0
      bind = SUPER, F,      exec, $notifycmd 'Fullscreen Mode'
      bind = SUPER, S,      pseudo,
      bind = SUPER, S,      exec, $notifycmd 'Pseudo Mode'
      bind = SUPER, Space,  togglefloating,
      bind = SUPER, Space,  centerwindow,

      # █▀▄▀█ █▀█ █░█ █▀ █▀▀   █▄▄ █ █▄░█ █▀▄ █ █▄░█ █▀▀
      # █░▀░█ █▄█ █▄█ ▄█ ██▄   █▄█ █ █░▀█ █▄▀ █ █░▀█ █▄█
      bindm=SUPER, mouse:272, movewindow
      bindm=SUPER, mouse:273, resizewindow

      # █▀█ █▀▀ █▀ █ ▀█ █▀▀
      # █▀▄ ██▄ ▄█ █ █▄ ██▄
      binde = SUPERALT, h, resizeactive, -20 0
      binde = SUPERALT, l, resizeactive, 20 0
      binde = SUPERALT, k, resizeactive, 0 -20
      binde = SUPERALT, j, resizeactive, 0 20
    '';
  };
}
