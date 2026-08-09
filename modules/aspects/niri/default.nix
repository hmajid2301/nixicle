{
  ...
}:
{
  flake-file.inputs = {
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nfsm = {
      url = "github:gvolpe/nfsm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/legacy-v4";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };
    noctalia-plugins = {
      url = "github:Mic92/noctalia-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.niri = {
    includes = [
      (
        {
          host,
          user,
          ...
        }:
        {
          nixos =
            {
              config,
              pkgs,
              lib,
              ...
            }:
            {
              services.greetd = {
                enable = true;
                useTextGreeter = !host.autologin;
                settings =
                  let
                    session = {
                      command = "niri-session &> /dev/null";
                      user = user.userName;
                    };
                    greeterSession = {
                      command =
                        let
                          theme =
                            with config.lib.stylix.colors.withHashtag;
                            "border=${base0D};text=${base05};prompt=${base0E};time=${base04};action=${base0B};button=${base0C};container=${base00};input=${base02}";
                        in
                        "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd 'niri-session &> /dev/null' --theme '${theme}'";
                      user = "greeter";
                    };
                  in
                  {
                    default_session = if host.autologin then session else greeterSession;
                  }
                  // lib.optionalAttrs host.autologin { initial_session = session; };
              };
            };
        }
      )
    ];
    persist.directories = [ "/var/cache/tuigreet" ];

    nixos =
      {
        config,
        pkgs,
        lib,
        inputs,
        ...
      }:
      {
        imports = [ inputs.niri.nixosModules.niri ];
        home-manager.sharedModules = lib.mkForce [ ];
        nixpkgs.overlays = [
          inputs.niri.overlays.niri
          inputs.noctalia-qs.overlays.default
        ];

        nix.settings = {
          extra-substituters = [ "https://niri.cachix.org" ];
          extra-trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
        };

        programs = {
          niri = {
            enable = true;
            package = pkgs.niri;
          };
          xwayland.enable = true;
        };

        environment = {
          sessionVariables.NIXOS_OZONE_WL = "1";
          systemPackages = with pkgs; [
            wl-clipboard
            slurp
            grim
            wf-recorder
            brightnessctl
            ffmpegthumbnailer
            gst_all_1.gst-libav
            gdk-pixbuf
            webp-pixbuf-loader
            nautilus-open-any-terminal
            nautilus-python
            gvfs
            nfs-utils
            # evolution-data-server deps
            gnome-online-accounts
            python3
          ];
          pathsToLink = [ "/share/nautilus-python/extensions" ];
          variables = {
            NAUTILUS_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";
            NAUTILUS_4_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";
            GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
              with pkgs.gst_all_1;
              [
                gst-plugins-good
                gst-plugins-bad
                gst-plugins-ugly
                gst-libav
              ]
            );
          };
        };

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gtk
            xdg-desktop-portal-gnome
          ];
          config.niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          };
          xdgOpenUsePortal = true;
        };

        security.polkit.enable = true;

        # evolution-data-server for calendar/contacts
        services.gnome.evolution-data-server.enable = true;
        programs.dconf.enable = true;
        services = {
          gvfs.enable = true;
          udisks2.enable = true;
        };
      };

    homeManager =
      {
        pkgs,
        config,
        lib,
        inputs,
        hostIsLaptop,
        ...
      }:
      let
        inherit (config.lib.stylix) colors;
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        imports = [ inputs.noctalia.homeModules.default ];

        home.packages =
          with pkgs;
          [
            cliphist
            wl-clipboard
            wdisplays
          ]
          ++ (with inputs.nfsm.packages.${pkgs.stdenv.hostPlatform.system}; [
            nfsm
            nfsm-cli
          ]);

        xdg.configFile = {
          "noctalia/plugins/display-config".source = "${inputs.noctalia-plugins}/display-config";
          "noctalia/plugins/rbw-provider".source = "${inputs.noctalia-plugins}/rbw-provider";
        };

        # Lock the screen before the system suspends (e.g. lid close with no
        # external monitor). noctalia's idle daemon races logind's suspend and
        # can leave the desktop unlocked on resume. This watches logind's
        # PrepareForSleep D-Bus signal — like swayidle's before-sleep hook —
        # and holds a delay inhibitor so the lock paints before sleep proceeds.
        # Lives in the systemd user layer so it works on NixOS and non-NixOS;
        # sleep.target is a system target unavailable to user units.
        systemd.user.services.lock-before-sleep = {
          Unit = {
            Description = "Lock noctalia before sleep";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${pkgs.writeShellScript "lock-before-sleep" ''
              exec ${pkgs.systemd}/bin/systemd-inhibit \
                --what=sleep --mode=delay --who=lock-before-sleep --why="Lock screen before sleep" \
                ${pkgs.dbus}/bin/dbus-monitor --system \
                  "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" \
                | while read -r line; do
                    case "$line" in
                      *"boolean true"*)
                        ${config.programs.noctalia-shell.package}/bin/noctalia-shell ipc call lockScreen lock \
                          || ${pkgs.systemd}/bin/loginctl lock-session
                        sleep 1
                        ;;
                    esac
                  done
            ''}";
            Restart = "on-failure";
            RestartSec = 2;
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };

        wayland.windowManager.niri = {
          enable = true;
          package = pkgs.niri;
          xwaylandSatellitePackage = pkgs.xwayland-satellite;
          extraConfig = ''
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
          '';
        };

        programs = {
          # Niri's configuration is managed by the official Home Manager
          # module at `wayland.windowManager.niri`; keep `programs` for the
          # other desktop tools below.

          # Rofi — app launcher fallback
          rofi = {
            enable = true;
            package = pkgs.rofi;
            terminal = "${pkgs.foot}/bin/foot";
            extraConfig = {
              modi = "run,drun,window";
              show-icons = true;
              drun-display-format = "{icon} {name}";
              location = 0;
              disable-history = false;
              hide-scrollbar = true;
              display-drun = "   Apps ";
              display-run = "   Run ";
              display-window = " 﩯  Window";
              display-Network = " 󰤨  Network";
              sidebar-mode = true;
            };
            theme = lib.mkForce {
              "*" = {
                bg-col = mkLiteral "#${colors.base00}";
                bg-col-light = mkLiteral "#${colors.base00}";
                border-col = mkLiteral "#${colors.base00}";
                selected-col = mkLiteral "#${colors.base00}";
                blue = mkLiteral "#${colors.base0D}";
                fg-col = mkLiteral "#${colors.base05}";
                fg-col2 = mkLiteral "#${colors.base08}";
                grey = mkLiteral "#737994";
                width = 600;
              };
              "element-text, element-icon , mode-switcher" = {
                background-color = mkLiteral "inherit";
                text-color = mkLiteral "inherit";
              };
              "window" = {
                height = mkLiteral "360px";
                border = mkLiteral "3px";
                border-color = mkLiteral "@border-col";
                background-color = mkLiteral "@bg-col";
              };
              "mainbox".background-color = mkLiteral "@bg-col";
              "inputbar" = {
                children = mkLiteral "[prompt,entry]";
                background-color = mkLiteral "@bg-col";
                border-radius = mkLiteral "5px";
                padding = mkLiteral "2px";
              };
              "prompt" = {
                background-color = mkLiteral "@blue";
                padding = mkLiteral "6px";
                text-color = mkLiteral "@bg-col";
                border-radius = mkLiteral "3px";
                margin = mkLiteral "20px 0px 0px 20px";
              };
              "entry" = {
                padding = mkLiteral "6px";
                margin = mkLiteral "20px 0px 0px 10px";
                text-color = mkLiteral "@fg-col";
                background-color = mkLiteral "@bg-col";
              };
              "listview" = {
                border = mkLiteral "0px 0px 0px";
                padding = mkLiteral "6px 0px 0px";
                margin = mkLiteral "10px 0px 0px 20px";
                columns = 2;
                lines = 5;
                background-color = mkLiteral "@bg-col";
              };
              "element" = {
                padding = mkLiteral "5px";
                background-color = mkLiteral "@bg-col";
                text-color = mkLiteral "@fg-col";
              };
              "element-icon".size = mkLiteral "25px";
              "element selected" = {
                background-color = mkLiteral "@selected-col";
                text-color = mkLiteral "@fg-col2";
              };
              "mode-switcher".spacing = 0;
              "button" = {
                padding = mkLiteral "10px";
                background-color = mkLiteral "@bg-col-light";
                text-color = mkLiteral "@grey";
                vertical-align = mkLiteral "0.5";
                horizontal-align = mkLiteral "0.5";
              };
              "button selected" = {
                background-color = mkLiteral "@bg-col";
                text-color = mkLiteral "@blue";
              };
              "message" = {
                background-color = mkLiteral "@bg-col-light";
                margin = mkLiteral "2px";
                padding = mkLiteral "2px";
                border-radius = mkLiteral "5px";
              };
              "textbox" = {
                padding = mkLiteral "6px";
                margin = mkLiteral "20px 0px 0px 20px";
                text-color = mkLiteral "@blue";
                background-color = mkLiteral "@bg-col-light";
              };
            };
          };

          # Noctalia shell
          noctalia-shell = {
            enable = true;
            settings = {
              appLauncher.enableClipboardHistory = true;
              ui = {
                fontDefault = config.stylix.fonts.sansSerif.name;
                fontFixed = config.stylix.fonts.monospace.name;
              };
              nightLight = {
                enabled = true;
                autoSchedule = true;
                dayTemp = "6500";
                nightTemp = "4000";
              };
              general = {
                lockOnSuspend = true;
                avatarImage = "/home/${config.home.username}/.face";
              };
              dock.enabled = false;
              bar = {
                floating = true;
                marginHorizontal = 0.25;
                marginVertical = 0.25;
                widgets = {
                  left = [
                    {
                      id = "Workspace";
                      characterCount = 2;
                    }
                  ];
                  center = [
                    {
                      id = "Clock";
                      formatHorizontal = "HH:mm:ss ddd, MMM dd";
                      usePrimaryColor = true;
                    }
                    { id = "KeepAwake"; }
                  ];
                  right =
                    [
                      { id = "Tray"; }
                      {
                        id = "NotificationHistory";
                        hideWhenZero = true;
                      }
                      {
                        id = "WiFi";
                        displayMode = "icon";
                      }
                    ]
                    ++ lib.optionals hostIsLaptop [
                      {
                        id = "Bluetooth";
                        displayMode = "icon";
                      }
                      {
                        id = "Brightness";
                        displayMode = "onhover";
                      }
                      { id = "Battery"; }
                    ]
                    ++ [
                      {
                        id = "Volume";
                        displayMode = "onhover";
                      }
                      {
                        id = "ControlCenter";
                        icon = "noctalia";
                      }
                    ];
                };
              };
              wallpaper = {
                directory = "/home/${config.home.username}/nixicle/packages/wallpapers/wallpapers";
                overviewEnabled = true;
              };
              location = {
                name = "london";
                showCalendarWeather = true;
              };
              calendar.cards = [
                {
                  enabled = true;
                  id = "calendar-header-card";
                }
                {
                  enabled = true;
                  id = "calendar-month-card";
                }
                {
                  enabled = false;
                  id = "timer-card";
                }
                {
                  enabled = true;
                  id = "weather-card";
                }
              ];
              controlCenter.shortcuts = {
                left = [
                  { id = "WiFi"; }
                  { id = "Bluetooth"; }
                  { id = "ScreenRecorder"; }
                  { id = "WallpaperSelector"; }
                ];
                right =
                  lib.optionals hostIsLaptop [
                    { id = "PowerProfile"; }
                  ]
                  ++ [
                    { id = "Notifications"; }
                    { id = "KeepAwake"; }
                    { id = "NightLight"; }
                  ];
              };
            };
          };

          # wlogout — session/power menu
          wlogout = {
            enable = true;
            layout = [
              {
                label = "lock";
                action = "noctalia-shell ipc call lockScreen lock";
                text = "Lock";
                keybind = "l";
              }
              {
                label = "hibernate";
                action = "systemctl hibernate";
                text = "Hibernate";
                keybind = "h";
              }
              {
                label = "logout";
                action = "loginctl terminate-user $USER";
                text = "Logout";
                keybind = "L";
              }
              {
                label = "shutdown";
                action = "systemctl poweroff";
                text = "Shutdown";
                keybind = "S";
              }
              {
                label = "suspend";
                action = "systemctl suspend";
                text = "Suspend";
                keybind = "s";
              }
              {
                label = "reboot";
                action = "systemctl reboot";
                text = "Reboot";
                keybind = "r";
              }
            ];
            style = builtins.readFile ./wlogout-style.css;
          };

          # cava — audio visualizer
          cava = {
            enable = true;
            settings = {
              general = {
                bars = 0;
                framerate = 60;
                stereo = false;
                sensitivity = 100;
                autosens = 1;
                lower_cutoff_freq = 50;
                higher_cutoff_freq = 10000;
              };
              input = {
                method = "pipewire";
                source = "auto";
              };
              output = {
                method = "ncurses";
                orientation = "bottom";
                channels = "stereo";
              };
              color = {
                gradient = 1;
                gradient_count = 6;
                gradient_color_1 = "'#${colors.base08}'";
                gradient_color_2 = "'#${colors.base09}'";
                gradient_color_3 = "'#${colors.base0A}'";
                gradient_color_4 = "'#${colors.base0B}'";
                gradient_color_5 = "'#${colors.base0C}'";
                gradient_color_6 = "'#${colors.base0D}'";
              };
              smoothing = {
                monstercat = 1;
                waves = 0;
                gravity = 100;
                ignore = 0;
              };
            };
          };
        };

        # wlsunset — night light, binds to niri session
        services.wlsunset = {
          enable = true;
          latitude = "51.5072";
          longitude = "-0.1275";
          temperature = {
            day = 6500;
            night = 4000;
          };
        };
        systemd.user.services.wlsunset = {
          Unit = {
            BindsTo = [ "niri.service" ];
            After = [ "niri.service" ];
            PartOf = lib.mkForce [ "niri.service" ];
          };
          Install.WantedBy = lib.mkForce [ ];
        };

        xdg.configFile."wlogout/icons" = {
          recursive = true;
          source = ./wlogout-icons;
        };

        # cliphist — clipboard history
        systemd.user.services.cliphist = {
          Unit = {
            Description = "Clipboard history service";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
            Restart = "on-failure";
            RestartSec = 1;
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
  };
}
