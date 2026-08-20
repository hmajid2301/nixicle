{ ... }:
{
  flake-file.inputs.nixgl.url = "github:nix-community/nixGL";
  flake-file.inputs.pam-shim = {
    url = "github:Cu3PO42/pam_shim/next";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.non-nixos = {
    homeManager =
      {
        pkgs,
        config,
        lib,
        inputs,
        ...
      }:
      {
        imports = [
          inputs.pam-shim.homeModules.default
        ];

        wayland.windowManager.niri.extraConfig = lib.mkForce ''
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
          spawn-at-startup "env" "-u" "LD_LIBRARY_PATH" "-u" "__EGL_VENDOR_LIBRARY_FILENAMES" "-u" "LIBGL_DRIVERS_PATH" "-u" "GBM_BACKENDS_PATH" "xwayland-satellite"
          spawn-at-startup "nfsm"
          spawn-at-startup "${
            let
              shimmedQuickshell = config.lib.pamShim.replacePam pkgs.quickshell;
            in
            pkgs.writeShellScript "noctalia-nixgl" ''
              export PATH="${pkgs.wlsunset}/bin:${pkgs.wl-clipboard}/bin:${pkgs.cliphist}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.bash}/bin:/run/wrappers/bin:${config.home.profileDirectory}/bin:/usr/bin:/bin"
              export NOCTALIA_PAM_SERVICE="quickshell"
              exec ${config.lib.nixGL.wrap shimmedQuickshell}/bin/qs -p ${config.programs.noctalia-shell.package}/share/noctalia-shell
            ''
          }"
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
        targets.genericLinux.nixGL = {
          inherit (inputs.nixgl) packages;
          defaultWrapper = "mesa";
        };

        pamShim.enable = true;

        nixpkgs.overlays = [
          inputs.noctalia-qs.overlays.default
          (_final: prev: {
            quickshell = config.lib.pamShim.replacePam prev.quickshell;
            nautilus = prev.nautilus.overrideAttrs (old: {
              postFixup = (old.postFixup or "") + ''
                mv $out/bin/nautilus $out/bin/.nautilus-gdk-wrapped
                makeWrapper $out/bin/.nautilus-gdk-wrapped $out/bin/nautilus \
                  --unset GDK_PIXBUF_MODULE_FILE
              '';
            });
          })
        ];

        home = {
          packages = with pkgs; [
            inputs.nixgl.packages.${pkgs.stdenv.hostPlatform.system}.nixGLIntel
            gdk-pixbuf
            webp-pixbuf-loader
            (lib.hiPrio (
              config.lib.nixGL.wrap (
                pkgs.writeShellScriptBin "google-chrome" ''
                  # Unset Nix GL paths to avoid conflicts with system Chrome (WebGL fix)
                  unset LIBVA_DRIVERS_PATH LIBGL_DRIVERS_PATH __EGL_VENDOR_LIBRARY_FILENAMES GBM_BACKENDS_PATH
                  # Strip Nix mesa/libglvnd paths from LD_LIBRARY_PATH so Chrome uses system GPU drivers
                  export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -v -E 'mesa|libglvnd|libgl1' | tr '\n' ':' | sed 's/:*$//')
                  exec /usr/bin/google-chrome-stable \
                    --no-sandbox \
                    --enable-features=UseOzonePlatform,VaapiVideoDecodeLinuxGL \
                    --ozone-platform=wayland \
                    "$@"
                ''
              )
            ))
          ];

          file.".local/bin/niri-session-nix" = {
            executable = true;
            text = ''
              #!/usr/bin/env bash
              . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
              exec ${config.home.profileDirectory}/bin/nixGLIntel ${config.home.profileDirectory}/bin/niri-session
            '';
          };

          activation.maskConflictingServices = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            $DRY_RUN_CMD mkdir -p $HOME/.config/systemd/user
            $DRY_RUN_CMD ln -sf /dev/null $HOME/.config/systemd/user/waybar.service
            $DRY_RUN_CMD ln -sf /dev/null $HOME/.config/systemd/user/swaync.service
            $DRY_RUN_CMD ${pkgs.systemd}/bin/systemctl --user daemon-reload || true
          '';
        };

        programs = {
          firefox.package = lib.mkForce (config.lib.nixGL.wrap pkgs.firefox);

          ghostty = lib.mkForce {
            package = config.lib.nixGL.wrap pkgs.ghostty;
          };
        };

        systemd.user.services.niri-env-setup = {
          Unit = {
            Description = "Import NIRI_SOCKET into systemd user environment";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
            ConditionEnvironment = "XDG_CURRENT_DESKTOP=niri";
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.writeShellScript "niri-env-setup" ''
              sleep 2
              NIRI_SOCKET=$(ls /run/user/$(id -u)/niri.sock* 2>/dev/null | head -1)
              if [ -n "$NIRI_SOCKET" ]; then
                ${pkgs.systemd}/bin/systemctl --user set-environment NIRI_SOCKET="$NIRI_SOCKET"
                echo "Set NIRI_SOCKET=$NIRI_SOCKET"
              else
                echo "Warning: NIRI_SOCKET not found, retrying..."
                sleep 3
                NIRI_SOCKET=$(ls /run/user/$(id -u)/niri.sock* 2>/dev/null | head -1)
                if [ -n "$NIRI_SOCKET" ]; then
                  ${pkgs.systemd}/bin/systemctl --user set-environment NIRI_SOCKET="$NIRI_SOCKET"
                  echo "Set NIRI_SOCKET=$NIRI_SOCKET"
                fi
              fi
            ''}";
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };

        xdg = {
          dataFile."applications/google-chrome.desktop".text = ''
            [Desktop Entry]
            Version=1.0
            Name=Google Chrome
            GenericName=Web Browser
            Comment=Access the Internet
            Exec=${config.home.homeDirectory}/.nix-profile/bin/google-chrome %U
            StartupNotify=true
            Terminal=false
            Icon=google-chrome
            Type=Application
            Categories=Network;WebBrowser;
            MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/google-chrome;
            Actions=new-window;new-private-window;

            [Desktop Action new-window]
            Name=New Window
            Exec=${config.home.homeDirectory}/.nix-profile/bin/google-chrome

            [Desktop Action new-private-window]
            Name=New Incognito Window
            Exec=${config.home.homeDirectory}/.nix-profile/bin/google-chrome --incognito
          '';

          dataFile."applications/com.mitchellh.ghostty.desktop".text = ''
            [Desktop Entry]
            Version=1.0
            Name=Ghostty
            Type=Application
            Comment=A terminal emulator
            Exec=${config.home.homeDirectory}/.nix-profile/bin/ghostty --gtk-single-instance=true
            Icon=com.mitchellh.ghostty
            Categories=System;TerminalEmulator;
            Keywords=terminal;tty;pty;
            StartupNotify=true
            StartupWMClass=com.mitchellh.ghostty
            Terminal=false
            Actions=new-window;
            X-GNOME-UsesNotifications=true
            X-TerminalArgExec=-e
            X-TerminalArgTitle=--title=
            X-TerminalArgAppId=--class=
            X-TerminalArgDir=--working-directory=
            X-TerminalArgHold=--wait-after-command

            [Desktop Action new-window]
            Name=New Window
            Exec=${config.home.homeDirectory}/.nix-profile/bin/ghostty
          '';

          configFile."environment.d/envvars.conf".text = ''
            PATH="$PATH:${config.home.homeDirectory}/.nix-profile/bin"
            XDG_DATA_DIRS="/usr/share/gnome:/usr/local/share:/usr/share:$XDG_DATA_DIRS"
            WAYLAND_DISPLAY=wayland-0
            XDG_CURRENT_DESKTOP=niri
            XDG_SESSION_TYPE=wayland
            MOZ_ENABLE_WAYLAND=1
            # Java AWT compatibility with tiling window managers
            _JAVA_AWT_WM_NONREPARENTING=1
            # Intel GPU stability settings for video conferencing
            MESA_LOADER_DRIVER_OVERRIDE=iris
            # Prevent aggressive power management during video calls
            intel_idle.max_cstate=1
          '';
        };
      };
  };
}
