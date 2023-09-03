{
  home,
  colorscheme,
  wallpaper,
}: let
  inherit (home.sessionVariables) TERMINAL BROWSER;
in ''
  set $mod Mod4
  set $left h
  set $down j
  set $up k
  set $right l

  input * {
  	xkb_layout "gb"
    xkb_options caps:escape
  }

  bindsym $mod+Shift+c reload

  client.focused          #${colorscheme.colors.base07} #${colorscheme.colors.base07} #ffffff
  client.unfocused        #${colorscheme.colors.base02} #${colorscheme.colors.base02} #ffffff

  # █▀▄▀█ █▀█ █░█ █▀ █▀▀   █▄▄ █ █▄░█ █▀▄ █ █▄░█ █▀▀
  # █░▀░█ █▄█ █▄█ ▄█ ██▄   █▄█ █ █░▀█ █▄▀ █ █░▀█ █▄█
  focus_follows_mouse yes
  # Use Mouse+$mod to drag floating windows to their wanted position
  floating_modifier $mod

  # ▄▀█ █░█ ▀█▀ █▀█   █▀ ▀█▀ ▄▀█ █▀█ ▀█▀
  # █▀█ █▄█ ░█░ █▄█   ▄█ ░█░ █▀█ █▀▄ ░█░
  exec mako &
  exec kanshi &
  exec sway-audio-idle-inhibit -w &
  exec gammastep-indicator &
  exec swaybg -i ${wallpaper} --mode fill &

  gaps inner 3
  gaps outer 5
  default_border pixel 3
  corner_radius 5

  # █▀ █░█ █▀█ █▀█ ▀█▀ █▀▀ █░█ ▀█▀ █▀
  # ▄█ █▀█ █▄█ █▀▄ ░█░ █▄▄ █▄█ ░█░ ▄█
  bindsym $mod+Return exec ${TERMINAL}
  bindsym $mod+b exec ${BROWSER}
  bindsym $mod+q kill
  bindsym $mod+a exec "/home/haseebmajid/.nix-profile/bin/rofi -i -modi drun -show drun"
  bindsym $mod+p exec pavucontrol
  # Drag floating windows by holding down $mod and left mouse button.
  # Resize them with right mouse button + $mod.
  # Despite the name, also works for non-floating windows.
  # Change normal to inverse to use left mouse button for resizing and right
  # mouse button for dragging.
  floating_modifier $mod normal
  # Exit sway (logs you out of your Wayland session)
  bindsym $mod+Shift+e exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit'

  # █▀▀ █▀█ █▀▀ █░█ █▀
  # █▀░ █▄█ █▄▄ █▄█ ▄█
  bindsym $mod+$left focus left
  bindsym $mod+$down focus down
  bindsym $mod+$up focus up
  bindsym $mod+$right focus right

  # Move the focused window with the same, but add Shift
  bindsym $mod+Shift+$left move left
  bindsym $mod+Shift+$down move down
  bindsym $mod+Shift+$up move up
  bindsym $mod+Shift+$right move right

  # █▀▀ █░█ ▄▀█ █▄░█ █▀▀ █▀▀   █░█░█ █▀█ █▀█ █▄▀ █▀ █▀█ ▄▀█ █▀▀ █▀▀
  # █▄▄ █▀█ █▀█ █░▀█ █▄█ ██▄   ▀▄▀▄▀ █▄█ █▀▄ █░█ ▄█ █▀▀ █▀█ █▄▄ ██▄
  bindsym $mod+1 workspace number 1
  bindsym $mod+2 workspace number 2
  bindsym $mod+3 workspace number 3
  bindsym $mod+4 workspace number 4
  bindsym $mod+5 workspace number 5
  bindsym $mod+6 workspace number 6
  bindsym $mod+7 workspace number 7
  bindsym $mod+8 workspace number 8
  bindsym $mod+9 workspace number 9
  bindsym $mod+0 workspace number 10

  # █▀▄▀█ █▀█ █░█ █▀▀   ▀█▀ █▀█   █░█░█ █▀█ █▀█ █▄▀ █▀ █▀█ ▄▀█ █▀▀ █▀▀
  # █░▀░█ █▄█ ▀▄▀ ██▄   ░█░ █▄█   ▀▄▀▄▀ █▄█ █▀▄ █░█ ▄█ █▀▀ █▀█ █▄▄ ██▄
  bindsym $mod+Shift+1 move container to workspace number 1
  bindsym $mod+Shift+2 move container to workspace number 2
  bindsym $mod+Shift+3 move container to workspace number 3
  bindsym $mod+Shift+4 move container to workspace number 4
  bindsym $mod+Shift+5 move container to workspace number 5
  bindsym $mod+Shift+6 move container to workspace number 6
  bindsym $mod+Shift+7 move container to workspace number 7
  bindsym $mod+Shift+8 move container to workspace number 8
  bindsym $mod+Shift+9 move container to workspace number 9
  bindsym $mod+Shift+0 move container to workspace number 10

  # Switch the current container between different layout styles
  bindsym $mod+s layout stacking
  bindsym $mod+w layout tabbed
  bindsym $mod+e layout toggle split

  # Make the current focus fullscreen
  bindsym $mod+f fullscreen

  # Toggle the current focus between tiling and floating mode
  bindsym $mod+Shift+space floating toggle

  # Swap focus between the tiling area and the floating area
  bindsym $mod+space focus mode_toggle

  # switch between current and last workspace
  bindsym $mod+slash workspace back_and_forth

  # Switch to prev/next workspace
  bindsym $mod+bracketright workspace next
  bindsym $mod+bracketleft workspace prev

  # Move the currently focused window to the scratchpad
  bindsym $mod+Shift+minus move scratchpad

  # Show the next scratchpad window or hide the focused scratchpad window.
  # If there are multiple scratchpad windows, this command cycles through them.
  bindsym $mod+minus scratchpad show

  bar {
     position top
     swaybar_command waybar
  }

  # █▀█ █▀▀ █▀ █ ▀█ █▀▀
  # █▀▄ ██▄ ▄█ █ █▄ ██▄
  bindsym $mod+r mode "resize"
  mode "resize" {
  	 bindsym $left resize shrink width 20px
  	 bindsym $down resize grow height 20px
  	 bindsym $up resize shrink height 20px
  	 bindsym $right resize grow width 20px

  	 bindsym Return mode "default"
  	 bindsym Escape mode "default"
  }
''
