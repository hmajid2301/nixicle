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

        programs.niri.settings.spawn-at-startup = lib.mkForce [
          {
            command = [
              "env"
              "-u"
              "LD_LIBRARY_PATH"
              "-u"
              "__EGL_VENDOR_LIBRARY_FILENAMES"
              "-u"
              "LIBGL_DRIVERS_PATH"
              "-u"
              "GBM_BACKENDS_PATH"
              "xwayland-satellite"
            ];
          }
          { command = [ "nfsm" ]; }
          {
            command = [
              "${
                let
                  shimmedQuickshell = config.lib.pamShim.replacePam pkgs.quickshell;
                in
                pkgs.writeShellScript "noctalia-nixgl" ''
                  export PATH="${pkgs.wlsunset}/bin:${pkgs.wl-clipboard}/bin:${pkgs.cliphist}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.bash}/bin:/run/wrappers/bin:${config.home.profileDirectory}/bin:/usr/bin:/bin"
                  export NOCTALIA_PAM_SERVICE="quickshell"
                  exec ${config.lib.nixGL.wrap shimmedQuickshell}/bin/qs -p ${config.programs.noctalia-shell.package}/share/noctalia-shell
                ''
              }"
            ];
          }
        ];
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
            Exec=nixGLIntel ${config.home.homeDirectory}/.nix-profile/bin/ghostty --gtk-single-instance=true
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
            Exec=nixGLIntel ${config.home.homeDirectory}/.nix-profile/bin/ghostty
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
