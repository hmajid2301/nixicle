{ inputs, config, pkgs, ... }: {
  imports = [
    inputs.hyprland.homeManagerModules.default
    ./eww.nix
    ./gammastep.nix
    ./mako.nix
    ./kanshi.nix
    ./rofi.nix
    ./swaylock.nix
    ./waybar.nix
    #./xdg.nix
  ];

  home.packages = with pkgs; [
    inputs.hypr-contrib.packages.${pkgs.system}.grimblast
    xdg-desktop-portal-hyprland
    # TODO: organise these
    kanshi
    via
    mtpfs
    brightnessctl
    xdg-utils
    gnome.nautilus
    gnome.sushi
    gnome.gnome-disk-utility
    gnome.gedit
    gnome.totem
    gnome.eog
    gnome.gvfs
    wl-clipboard
    pamixer
    playerctl
    sway-contrib.grimshot
    swaybg
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
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
        col.group_border_active=0xff${config.colorscheme.colors.base0B}
        col.group_border=0xff${config.colorscheme.colors.base04}
      }

      decoration {
        rounding=5
      }

      bind = SUPER_SHIFT, b, exec, firefox
      bind = SUPER, Return, exec, alacritty
      bind = SUPER, a, exec, rofi -show drun -modi drun
      bind = SUPER, w, exec, makoctl dismiss

      # auto-start
      exec-once = mako &
      exec-once = kanshi &
      exec-once = swayidle -w &
      exec-once = waybar &
      exec=swaybg -i ~/dotfiles/home-manager/wallpapers/spill.jpg --mode fill &
      exec-once = ~/dotfiles/home-manager/desktops/hyprland/scripts/laptop_lid_switch.sh
    

      bindl=,switch:Lid Switch, exec, ~/dotfiles/home/haseeb/features/desktops/hyprland/scripts/laptop_lid_switch.sh
      #monitor=DP-1,3840x2160@60,3840x0,1
      #monitor=DP-2,3840x2160@60,0x0,1

      # Other
      bind=CONTROL_ALT,DELETE,exec,~/dotfiles/home-manager/desktops/hyprland/scripts/power_menu.sh

      # Lock screen
      bind=,XF86Launch5,exec,swaylock -S
      bind=,XF86Launch4,exec,swaylock -S
      bind=SUPER,backspace,exec,swaylock -S

      # Scratchpad
      bind=SUPER,u,togglespecialworkspace
      bind=SUPERSHIFT,u,movetoworkspace,special

      # Screenshots
      bind=,Print,exec,grimblast --notify copy output
      bind=SHIFT,Print,exec,grimblast --notify copy active
      bind=CONTROL,Print,exec,grimblast --notify copy screen
      bind=SUPER,Print,exec,grimblast --notify copy window
      bind=ALT,Print,exec,grimblast --notify copy area
      bind=SUPER,bracketleft,exec,grimblast --notify --cursor copysave area ~/Pictures/$(date "+%Y-%m-%d"T"%H:%M:%S_no_watermark").png
      bind=SUPER,bracketright,exec, grimblast --notify --cursor copy area

      # Keyboard controls (brightness, media, sound, etc)
      bind=,XF86MonBrightnessUp,exec, ~/dotfiles/home-manager/desktops/hyprland/scripts/brightness.sh --inc
      bind=,XF86MonBrightnessDown,exec, ~/dotfiles/home-manager/desktops/hyprland/scripts/brightness.sh --dec
      bind=,XF86AudioRaiseVolume,exec, ~/dotfiles/home-manager/desktops/hyprland/scripts/volume.sh --inc
      bind=,XF86AudioLowerVolume,exec, ~/dotfiles/home-manager/desktops/hyprland/scripts/volume.sh --dec
      bind=,XF86AudioMute,exec, ~/dotfiles/home-manager/desktops/hyprland/scripts/volume.sh --toggle
      bind=,XF86AudioMicMute,exec, ~/dotfiles/home-manager/desktops/hyprland/scripts/volume.sh --toggle-mic
    
      bind=,XF86AudioNext,exec,playerctl next
      bind=,XF86AudioPrev,exec,playerctl previous
      bind=,XF86AudioPlay,exec,playerctl play-pause
      bind=,XF86AudioStop,exec,playerctl stop
      bind=ALT,XF86AudioNext,exec,playerctld shift
      bind=ALT,XF86AudioPrev,exec,playerctld unshift
      bind=ALT,XF86AudioPlay,exec,systemctl --user restart playerctld


      bind=SUPER,left,movefocus,l
      bind=SUPER,right,movefocus,r
      bind=SUPER,up,movefocus,u
      bind=SUPER,down,movefocus,d
      bind=SUPER,h,movefocus,l
      bind=SUPER,l,movefocus,r
      bind=SUPER,k,movefocus,u
      bind=SUPER,j,movefocus,d

      bind=SUPERSHIFT,left,swapwindow,l
      bind=SUPERSHIFT,right,swapwindow,r
      bind=SUPERSHIFT,up,swapwindow,u
      bind=SUPERSHIFT,down,swapwindow,d
      bind=SUPERSHIFT,h,swapwindow,l
      bind=SUPERSHIFT,l,swapwindow,r
      bind=SUPERSHIFT,k,swapwindow,u
      bind=SUPERSHIFT,j,swapwindow,d

      bind=SUPERCONTROL,left,focusmonitor,l
      bind=SUPERCONTROL,right,focusmonitor,r
      bind=SUPERCONTROL,up,focusmonitor,u
      bind=SUPERCONTROL,down,focusmonitor,d
      bind=SUPERCONTROL,h,focusmonitor,l
      bind=SUPERCONTROL,l,focusmonitor,r
      bind=SUPERCONTROL,k,focusmonitor,u
      bind=SUPERCONTROL,j,focusmonitor,d

      bind=SUPERCONTROL,1,focusmonitor,DP-7
      bind=SUPERCONTROL,2,focusmonitor,DP-5

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

      bind=SUPERALT,left,movecurrentworkspacetomonitor,l
      bind=SUPERALT,right,movecurrentworkspacetomonitor,r
      bind=SUPERALT,up,movecurrentworkspacetomonitor,u
      bind=SUPERALT,down,movecurrentworkspacetomonitor,d
      bind=SUPERALT,h,movecurrentworkspacetomonitor,l
      bind=SUPERALT,l,movecurrentworkspacetomonitor,r
      bind=SUPERALT,k,movecurrentworkspacetomonitor,u
      bind=SUPERALT,j,movecurrentworkspacetomonitor,d


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

      bind = SUPER, Q, killactive,
      bind = SUPERSHIFT, Space, togglefloating,
      bind = SUPER,F,fullscreen

      #-- Mouse Buttons ----------------------------------------------
      bindm=SUPER, mouse:272, movewindow
      bindm=SUPER, mouse:273, resizewindow
    '';
  };
}
