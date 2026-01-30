{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.roles.non-nixos;
in
{
  imports = [ ../../system/nix ];

  options.roles.non-nixos = {
    enable = mkEnableOption "Enable non-NixOS system configurations (Ubuntu, Debian, Fedora, etc.)";
  };

  config = mkIf cfg.enable {
    targets.genericLinux.nixGL = {
      inherit (inputs.nixgl) packages;
      defaultWrapper = "mesa";
    };

    pamShim.enable = true;

    nixpkgs.overlays = [
      (final: prev: {
        quickshell = config.lib.pamShim.replacePam prev.quickshell;
      })
    ];

    home.packages = with pkgs; [
      nixgl.nixGLIntel
      (lib.hiPrio (config.lib.nixGL.wrap totem))
      (lib.hiPrio (
        config.lib.nixGL.wrap (
          pkgs.writeShellScriptBin "google-chrome" ''
            exec ${pkgs.google-chrome}/bin/google-chrome-stable \
              --no-sandbox \
              --enable-features=UseOzonePlatform,VaapiVideoDecodeLinuxGL \
              --ozone-platform=wayland \
              "$@"
          ''
        )
      ))
    ];

    programs = {
      firefox.package = config.lib.nixGL.wrap pkgs.firefox;

      ghostty = lib.mkForce {
        package = config.lib.nixGL.wrap pkgs.ghostty;
      };
    };

    systemd.user.services.noctalia-shell = mkIf config.desktops.addons.noctalia.enable (
      let
        shimmedQuickshell = config.lib.pamShim.replacePam pkgs.quickshell;
      in
      {
        Service = {
          ExecStart = lib.mkForce "${pkgs.writeShellScript "noctalia-nixgl" ''
            export PATH="${pkgs.wlsunset}/bin:${pkgs.wl-clipboard}/bin:${pkgs.cliphist}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.bash}/bin:/run/wrappers/bin:${config.home.profileDirectory}/bin:/usr/bin:/bin"
            exec ${config.lib.nixGL.wrap shimmedQuickshell}/bin/quickshell -p ${config.programs.noctalia-shell.package}/share/noctalia-shell
          ''}";
        };
      }
    );

    home.file.".local/bin/niri-session-nix" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
        exec ${config.home.profileDirectory}/bin/nixGLIntel ${config.home.profileDirectory}/bin/niri-session
      '';
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

    home.activation.maskConflictingServices = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/.config/systemd/user
      $DRY_RUN_CMD ln -sf /dev/null $HOME/.config/systemd/user/waybar.service
      $DRY_RUN_CMD ln -sf /dev/null $HOME/.config/systemd/user/swaync.service
      $DRY_RUN_CMD ${pkgs.systemd}/bin/systemctl --user daemon-reload || true
    '';

    xdg.dataFile."applications/com.mitchellh.ghostty.desktop".text = ''
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

    xdg.configFile."environment.d/envvars.conf".text = ''
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
}
