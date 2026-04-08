{ den, inputs, lib, ... }:
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
    dankMaterialShell = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };
  };

  den.aspects.niri = {
    includes = [
      ({ host, user, ... }: {
        nixos = { config, pkgs, lib, ... }: {
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
                      theme = with config.lib.stylix.colors.withHashtag; "border=${base0D};text=${base05};prompt=${base0E};time=${base04};action=${base0B};button=${base0C};container=${base00};input=${base02}";
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
      })
      (import ../services/_persist-forwarder.nix { inherit den lib; })
    ];
    persist.directories = [ "/var/cache/tuigreet" ];

    nixos = { config, pkgs, lib, inputs, ... }: {
      imports = [ inputs.niri.nixosModules.niri ];
      nixpkgs.overlays = [
        inputs.niri.overlays.niri
        inputs.noctalia-qs.overlays.default
      ];

      nix.settings = {
        substituters = [ "https://niri.cachix.org" ];
        trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
      };

      programs = {
        niri.enable = true;
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
          default = [ "gnome" "gtk" ];
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

    homeManager = { pkgs, config, lib, inputs, ... }:
      let
        inherit (config.lib.stylix) colors;
        inherit (config.lib.formats.rasi) mkLiteral;

        noctalia = cmd: [ "noctalia-shell" "ipc" "call" ] ++ (pkgs.lib.splitString " " cmd);
      in
      {
        imports = [
          inputs.dankMaterialShell.homeModules.dank-material-shell
          inputs.noctalia.homeModules.default
        ];
        # nfsm — floating window session manager + cliphist
        home.packages = with pkgs; [ cliphist wl-clipboard ]
          ++ (with inputs.nfsm.packages.${pkgs.stdenv.hostPlatform.system}; [ nfsm nfsm-cli ]);

        programs = {
          niri.settings = {
            outputs."*".scale = 1.0;

            input = {
              keyboard.xkb = { };
              touchpad.tap = true;
              touchpad.natural-scroll = true;
              focus-follows-mouse = {
                enable = true;
                max-scroll-amount = "0%";
              };
              workspace-auto-back-and-forth = true;
            };

            prefer-no-csd = true;
            hotkey-overlay.skip-at-startup = true;
            gestures.hot-corners.enable = false;

            layout = {
              gaps = 8;
              default-column-width.proportion = 0.5;
              preset-column-widths = [
                { proportion = 0.33333; }
                { proportion = 0.5; }
                { proportion = 0.66667; }
                { proportion = 1.0; }
              ];

              center-focused-column = "always";
              always-center-single-column = true;
            };

            workspaces = { };

            window-rules = [
              {
                clip-to-geometry = true;
                geometry-corner-radius = {
                  bottom-left = 10.0; bottom-right = 10.0;
                  top-left = 10.0; top-right = 10.0;
                };
              }
              {
                matches = [
                  { app-id = "^google-chrome$"; title = ".*Meet.*"; }
                  { app-id = "^google-chrome$"; title = ".*meet\\.google\\.com.*"; }
                  { app-id = "^google-chrome$"; title = ".*Google Meet.*"; }
                  { app-id = "^google-chrome$"; title = ".*Zoom.*"; }
                  { app-id = "^google-chrome$"; title = ".*zoom\\.us.*"; }
                  { app-id = "^google-chrome$"; title = ".*Join Zoom Meeting.*"; }
                  { app-id = "^google-chrome$"; title = "^$"; }
                  { app-id = "^firefox$"; title = ".*PayPal.*"; }
                  { app-id = "^firefox$"; title = ".*popup.*"; }
                  { app-id = "^firefox$"; title = ".*Authentication.*"; }
                  { app-id = "^firefox$"; title = ".*Login.*"; }
                  { app-id = "^firefox$"; title = ".*Security.*"; }
                  { app-id = "^org.mozilla.firefox$"; title = ".*PayPal.*"; }
                  { app-id = "^org.mozilla.firefox$"; title = ".*popup.*"; }
                  { app-id = "^firefox$"; title = ".*Bitwarden.*"; }
                  { app-id = "^org.mozilla.firefox$"; title = ".*Bitwarden.*"; }
                  { app-id = "^firefox$"; title = ".*Extension.*Bitwarden.*"; }
                  { app-id = "^bitwarden$"; }
                  { app-id = "^com.bitwarden.desktop$"; }
                  { app-id = "^firefox$"; title = "^$"; }
                  { app-id = "^org.mozilla.firefox$"; title = "^$"; }
                ];
                default-column-width = { };
                open-on-output = "";
                open-maximized = false;
                open-fullscreen = false;
              }
            ];

            layer-rules = [
              {
                matches = [ { namespace = "^noctalia-overview.*"; } ];
                place-within-backdrop = true;
              }
            ];

            spawn-at-startup = [
              { command = [ "xwayland-satellite" ]; }
              { command = [ "nfsm" ]; }
            ];

            binds = with config.lib.niri.actions; {
              "Mod+Return".action.spawn = [ "ghostty" ];
              "Mod+E".action.spawn = [ "nautilus" ];

              "Mod+Space".action.spawn = noctalia "launcher toggle";
              "Mod+B".action.spawn = [ "rofi" "-show" "drun" ];
              "Mod+S".action.spawn = noctalia "controlCenter toggle";
              "Mod+Comma".action.spawn = noctalia "settings toggle";
              "Mod+V".action.spawn = noctalia "launcher clipboard";

              "Mod+Q".action = close-window;
              "Mod+F".action = fullscreen-window;
              "Mod+Shift+F".action.spawn = "nfsm-cli";
              "Mod+T".action = toggle-window-floating;
              "Mod+O".action = toggle-overview;
              "Mod+C".action = center-column;
              "Mod+M".action = maximize-column;
              "Mod+W".action = toggle-column-tabbed-display;

              "Mod+H".action = focus-column-or-monitor-left;
              "Mod+L".action = focus-column-or-monitor-right;
              "Mod+J".action = focus-window-or-workspace-down;
              "Mod+K".action = focus-window-or-workspace-up;

              "Mod+Ctrl+J".action = focus-workspace-down;
              "Mod+Ctrl+K".action = focus-workspace-up;

              "Mod+Shift+H".action = move-column-to-monitor-left;
              "Mod+Shift+L".action = move-column-to-monitor-right;
              "Mod+Shift+J".action = move-window-to-monitor-down;
              "Mod+Shift+K".action = move-window-to-monitor-up;

              "Mod+Ctrl+H".action = consume-or-expel-window-left;
              "Mod+Ctrl+L".action = consume-or-expel-window-right;

              "Mod+R".action = switch-preset-column-width;
              "Mod+Shift+R".action = switch-preset-column-width-back;
              "Mod+Equal".action.set-column-width = "+10%";
              "Mod+Minus".action.set-column-width = "-10%";
              "Mod+Shift+Equal".action.set-window-height = "+10%";
              "Mod+Shift+Minus".action.set-window-height = "-10%";

              "Mod+Ctrl+Shift+H".action = focus-monitor-left;
              "Mod+Ctrl+Shift+L".action = focus-monitor-right;
              "Mod+Ctrl+Shift+J".action = focus-monitor-down;
              "Mod+Ctrl+Shift+K".action = focus-monitor-up;

              "Mod+Alt+Shift+H".action = move-window-to-monitor-left;
              "Mod+Alt+Shift+L".action = move-window-to-monitor-right;
              "Mod+Alt+Shift+J".action = move-window-to-monitor-down;
              "Mod+Alt+Shift+K".action = move-window-to-monitor-up;

              "Mod+Alt+H".action = move-column-left;
              "Mod+Alt+L".action = move-column-right;
              "Mod+Alt+J".action = move-window-down;
              "Mod+Alt+K".action = move-window-up;

              "Mod+1".action.focus-workspace = 1; "Mod+2".action.focus-workspace = 2;
              "Mod+3".action.focus-workspace = 3; "Mod+4".action.focus-workspace = 4;
              "Mod+5".action.focus-workspace = 5; "Mod+6".action.focus-workspace = 6;
              "Mod+7".action.focus-workspace = 7; "Mod+8".action.focus-workspace = 8;
              "Mod+9".action.focus-workspace = 9; "Mod+0".action.focus-workspace = 10;

              "Mod+Shift+1".action.move-window-to-workspace = 1; "Mod+Shift+2".action.move-window-to-workspace = 2;
              "Mod+Shift+3".action.move-window-to-workspace = 3; "Mod+Shift+4".action.move-window-to-workspace = 4;
              "Mod+Shift+5".action.move-window-to-workspace = 5; "Mod+Shift+6".action.move-window-to-workspace = 6;
              "Mod+Shift+7".action.move-window-to-workspace = 7; "Mod+Shift+8".action.move-window-to-workspace = 8;
              "Mod+Shift+9".action.move-window-to-workspace = 9; "Mod+Shift+0".action.move-window-to-workspace = 10;

              "Mod+Ctrl+Shift+1".action.move-column-to-workspace = 1; "Mod+Ctrl+Shift+2".action.move-column-to-workspace = 2;
              "Mod+Ctrl+Shift+3".action.move-column-to-workspace = 3; "Mod+Ctrl+Shift+4".action.move-column-to-workspace = 4;
              "Mod+Ctrl+Shift+5".action.move-column-to-workspace = 5; "Mod+Ctrl+Shift+6".action.move-column-to-workspace = 6;
              "Mod+Ctrl+Shift+7".action.move-column-to-workspace = 7; "Mod+Ctrl+Shift+8".action.move-column-to-workspace = 8;
              "Mod+Ctrl+Shift+9".action.move-column-to-workspace = 9; "Mod+Ctrl+Shift+0".action.move-column-to-workspace = 10;

              "Print".action.spawn = [ "niri" "msg" "action" "screenshot" ];
              "Shift+Print".action.spawn = [ "niri" "msg" "action" "screenshot-screen" ];
              "Mod+Print".action.spawn = [ "niri" "msg" "action" "screenshot-window" ];

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
            systemd.enable = true;
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
                  left = [ { id = "Workspace"; characterCount = 2; } ];
                  center = [
                    { id = "Clock"; formatHorizontal = "HH:mm:ss ddd, MMM dd"; usePrimaryColor = true; }
                    { id = "KeepAwake"; }
                  ];
                  right = [
                    { id = "Tray"; }
                    { id = "NotificationHistory"; hideWhenZero = true; }
                    { id = "WiFi"; displayMode = "icon"; }
                    { id = "Volume"; displayMode = "onhover"; }
                    { id = "ControlCenter"; icon = "noctalia"; }
                  ];
                };
              };
              wallpaper = {
                directory = "/home/${config.home.username}/nixicle/packages/wallpapers/wallpapers";
                overviewEnabled = true;
              };
              location = { name = "london"; showCalendarWeather = true; };
              calendar.cards = [
                { enabled = true; id = "calendar-header-card"; }
                { enabled = true; id = "calendar-month-card"; }
                { enabled = false; id = "timer-card"; }
                { enabled = true; id = "weather-card"; }
              ];
              controlCenter.shortcuts = {
                left = [
                  { id = "WiFi"; }
                  { id = "Bluetooth"; }
                  { id = "ScreenRecorder"; }
                  { id = "WallpaperSelector"; }
                ];
                right = [
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
              { label = "lock"; action = "noctalia-shell ipc call lockScreen lock"; text = "Lock"; keybind = "l"; }
              { label = "hibernate"; action = "systemctl hibernate"; text = "Hibernate"; keybind = "h"; }
              { label = "logout"; action = "loginctl terminate-user $USER"; text = "Logout"; keybind = "L"; }
              { label = "shutdown"; action = "systemctl poweroff"; text = "Shutdown"; keybind = "S"; }
              { label = "suspend"; action = "systemctl suspend"; text = "Suspend"; keybind = "s"; }
              { label = "reboot"; action = "systemctl reboot"; text = "Reboot"; keybind = "r"; }
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
              input = { method = "pipewire"; source = "auto"; };
              output = { method = "ncurses"; orientation = "bottom"; channels = "stereo"; };
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
              smoothing = { monstercat = 1; waves = 0; gravity = 100; ignore = 0; };
            };
          };
        };

        # wlsunset — night light, binds to niri session
        services.wlsunset = {
          enable = true;
          latitude = "51.5072";
          longitude = "-0.1275";
          temperature = { day = 6500; night = 4000; };
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
