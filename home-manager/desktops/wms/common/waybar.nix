{ pkgs, config, ... }:
let
  inherit (config) colorscheme;
in
{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = false;
    };
    settings = [
      {
        layer = "top";
        position = "top";
        height = 60;
        margin = "0 0 0 0";
        modules-left = [
          "hyprland/workspaces"
        ];
        modules-center = [
          "custom/notification"
          "clock"
          "idle_inhibitor"
        ];
        modules-right = [
          "backlight"
          "battery"

          "temperature"
          "cpu"
          "memory"

          "wireplumber"
          "network"

          "tray"
        ];
        "hyprland/workspaces" = {
          format = "{icon}";
          sort-by-number = true;
          active-only = false;
          format-icons = {
            "1" = " 󰲌 ";
            "2" = "  ";
            "3" = " 󰎞 ";
            "4" = "  ";
            "5" = "  ";
            "6" = " 󰺵 ";
            "7" = "  ";
            urgent = "  ";
            focused = "  ";
            default = "  ";
          };
          on-click = "activate";
        };
        clock = {
          format = "󰃰 {:%a, %d %b, %I:%M %p}";
          interval = 1;
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            "mode-mon-col" = 3;
            "weeks-pos" = "right";
            "on-scroll" = 1;
            "on-click-right" = "mode";
            format = {
              months = "<span color='#cba6f7'><b>{}</b></span>";
              days = "<span color='#b4befe'><b>{}</b></span>";
              weeks = "<span color='#89dceb'><b>W{}</b></span>";
              weekdays = "<span color='#f2cdcd'><b>{}</b></span>";
              today = "<span color='#f38ba8'><b><u>{}</u></b></span>";
            };
          };
        };
        "custom/notification" = {
          tooltip = false;
          format = "{} {icon}";
          "format-icons" = {
            notification = "󱅫";
            none = "";
            "dnd-notification" = " ";
            "dnd-none" = "󰂛";
            "inhibited-notification" = " ";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = " ";
            "dnd-inhibited-none" = " ";
          };
          "return-type" = "json";
          "exec-if" = "which swaync-client";
          exec = "swaync-client -swb";
          "on-click" = "swaync-client -t -sw";
          "on-click-right" = "swaync-client -d -sw";
          escape = true;
        };
        "idle_inhibitor" = {
          format = "{icon}";
          format-icons = {
            activated = "  ";
            deactivated = "  ";

          };
        };
        backlight = {
          format = " {percent}%";
        };
        battery = {
          states = {
            good = 80;
            warning = 50;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-alt = "{time}";
          format-charging = "  {capacity}%";
          format-plugged = "";
          format-icons = [ "󰁻 " "󰁽 " "󰁿 " "󰂁 " "󰂂 " ];
        };
        cpu = {
          interval = 1;
          format = " {usage}%";
        };
        memory = {
          interval = 30;
          format = "󰍛 {used:0.1f}GiB";
          tooltip-format = "{used = 0.1f}GiB/{avail = 0.1f}GiB";
        };
        network = {
          interval = 1;
          format-wifi = "  {essid}";
          format-ethernet = "󰈀";
          format-disconnected = "󱚵";
          tooltip-format = ''
            {ifname}
            {ipaddr}/{cidr}
            {signalstrength}
            Up: {bandwidthUpBits}
            Down: {bandwidthDownBits}
          '';
        };
        wireplumber = {
          scroll-step = 2;
          format = "{icon} {volume}%";
          format-muted = "";
          format-icons = [ "" "" ];
          "on-click" = "helvum";
        };
        tray = {
          icon-size = 16;
          spacing = 8;
        };
      }
    ];

    style =
      # css
      ''
                                                        @define-color base      #${colorscheme.colors.base00};
                                                        @define-color blue      #${colorscheme.colors.base0D};
                                                        @define-color rosewater #${colorscheme.colors.base06};
                                                        @define-color lavender  #${colorscheme.colors.base07};
                                                        @define-color teal      #${colorscheme.colors.base0C};
                                                        @define-color yellow    #${colorscheme.colors.base0A};
                                                        @define-color green     #${colorscheme.colors.base0B};
                                                        @define-color red       #${colorscheme.colors.base08};
                                                        @define-color mauve     #${colorscheme.colors.base0E};
                                                        @define-color flamingo  #${colorscheme.colors.base0F};

                                                        * { 
                                                        	border: 0;
                                                        	padding: 0 0;
                                                        	font-family: ${config.my.settings.fonts.monospace};
                                                        	font-size: 18px;
                                                        	color: white;
                                                        }

                                                        window#waybar {
                                                        	border: 0px solid rgba(0, 0, 0, 0);
                                                        	background-color: rgba(0, 0, 0, 0);
                                                        }

                                                        #workspaces {
                                                        	background-color: #11111b;
                                                        	border-radius: 5px;
                                                        	margin: 8px;
                                                        }

                                                        #workspaces button {
                                                        	color: @base;
                                                        	border-radius: 5px;
                                                        	padding-right: 5px;
                                                        	margin: 2px 4px;
                                                        }

                                                        #workspaces button:hover {
                                                        	color: @lavender;
                                                        } 

                                                        #workspaces button.active * {
                                                        	border-radius: 7px;
                                                        	background-color: @lavender;
                                                        } 

                                                        #workspaces button.visible {
                                                        	background-color: @lavender;
                                                        }

                                                        #workspaces button.visible * {
                                                        	color: @base;
                                                        } 

                                                        #clock,
                                                        #battery,
                                                        #cpu,
                                                        #memory,
                                                        #temperature,
                                                        #backlight,
                                                        #network,
                                                        #wireplumber,
                                                        #mode,
                                                        #tray,
                                                        #idle_inhibitor,
                                                        #custom-notification {
                                                        	border-style: solid;
                                                        	background-color: shade(@base, 1);
                                                        	margin: 8px 0;
                                                        	padding: 5px 0;
                                                        } 

                                                        #custom-notification {
                                                        	margin-left: 10px;
                                                        	padding: 0 20px 0 20px;
                                                        	border-radius: 10px 0 0 10px;
                                                        	color: @lavender;
                                                        }

                                                        #clock {
                                                					border-radius: 0; 
                                                        	padding: 0 20px 0 20px;
                                                        	font-weight: bold;
                                                        	color: @lavender;
                                                        } 

                                                        #idle_inhibitor.deactivated {
                                                        	border-radius: 0 10px 10px 0;
                                                        	color: @lavender;
                                                        }

                                                        #idle_inhibitor.activated {
                                                        	border-radius: 0 10px 10px 0;
                                                        	 color: @green;
                                                        }

                                                        #tray {
                                                        	border-radius: 5px;
                                                 /*        	padding: 0 10px; */
                                        									/* margin: 0 10px;  */
                                                        }

                                                        #backlight {
                                                        	color: @yellow;
                                                        	padding: 0 10px 0 20px;
                                                        	border-radius: 10px 0 0 10px;
                                                        	margin-left: 10px;
                                                        } 

                                                        #battery {
                                                        	color: @lavender;
                                                        	padding: 0 20px 0 10px;
                                                        	border-radius: 0 10px 10px 0;
                                                        	margin-right: 10px;
                                                        }

                                                        #battery.critical:not(.charging) {
                                                        	color: @red;
                                                        	animation-name: blink;
                                                        	animation-duration: 0.5s;
                                                        	animation-timing-function: linear;
                                                        	animation-iteration-count: infinite;
                                                        	animation-direction: alternate;
                                                        }

                                                        #battery.charging {
                                                        color: @green;
                                                        }

                                                        @keyframes blink {
                                                        	to {
                                                        		 color: @red;
                                                        	}
                                                        }

                																			#temperature {
                																				 color: @teal;
                																				 border-radius: 10px 0 0 10px;
                																			}

                																			#temperature.critical {
                																				 color: @red;
                																			}

                																			#cpu {
                																				 color: @blue;
                																			}

                																			#memory {
                																				 color: @flamingo;
                																				 border-radius: 0 10px 10px 0;
                																				 margin-right: 5px;
                																			}

        																							#network {
        																							 color: @lavender;
        																							 border-radius: 0 10px 10px 0;
        																							 margin-right: 10px;
        																							}

        																							#network.disconnected {
        																							 color: @red;
        																							}
        																							
        																							#wireplumber {
        																							 color: @lavender;
        																							 border-radius: 10px 0 0 10px;
        																							 margin-right: 10px;
        																							}

        																							#wireplumber.muted {
        																							 color: @red;
        																							}

      '';
  };
}
