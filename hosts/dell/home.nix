{
  config,
  pkgs,
  lib,
  ...
}:
{
  roles = {
    desktop.enable = true;
    non-nixos.enable = true;
  };

  # Fix PAM authentication for non-NixOS systems using pam_shim
  # See: https://github.com/nix-community/home-manager/issues/7027
  # See: https://github.com/Cu3PO42/pam_shim
  pamShim.enable = true;

  nix.package = lib.mkDefault pkgs.nix;

  home.packages = with pkgs; [
    semgrep
    pre-commit
    bun

    # TODO: stylix doesn't work with gnome 46 at the moment
    pkgs.nixicle.monolisa
    pkgs.noto-fonts-color-emoji
    pkgs.noto-fonts
    pkgs.source-serif
    pkgs.nerd-fonts.symbols-only
    pkgs.dejavu_fonts
    pkgs.liberation_ttf
  ];

  # TODO: Don't hardcode UID - use dynamic resolution
  sops.defaultSymlinkPath = lib.mkForce "/run/user/1003/secrets";
  sops.defaultSecretsMountPoint = lib.mkForce "/run/user/1003/secrets.d";

  # TODO: Disable stylix for now (doesn't work with GNOME 46)
  styles.stylix.enable = lib.mkForce false;

  stylix = lib.mkForce {
    enable = false;
    autoEnable = false;
    targets.gnome.enable = false;
    targets.gnome.useWallpaper = false;
    image = null;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
  };

  programs.ghostty = lib.mkForce {
    enable = true;
    enableFishIntegration = true;
    package = config.lib.nixGL.wrap pkgs.ghostty;

    settings = {
      "font-family" = [
        "MonoLisa"
        "Symbols Nerd Font"
        "Noto Color Emoji"
      ];

      theme = "Catppuccin Mocha";
      command = "fish";
      gtk-titlebar = false;
      gtk-tabs-location = "hidden";
      gtk-single-instance = true;
      font-size = 14;
      window-padding-x = 6;
      window-padding-y = 6;
      copy-on-select = "clipboard";
      cursor-style = "block";
      confirm-close-surface = false;
      keybind = [ "ctrl+shift+plus=increase_font_size:1" ];
    };
  };

  desktops = {
    niri = {
      enable = true;
      outputs = {
        "eDP-1" = {
          position = {
            x = 0;
            y = 0;
          };
        };
        "HDMI-A-2" = {
          position = {
            x = 1536;
            y = 0;
          };
        };
      };
    };

    addons = {
      noctalia = {
        standalone = true;
        laptop = true;
      };
    };
  };

  systemd.user.services.noctalia-shell = lib.mkIf config.desktops.addons.noctalia.enable (
    let
      # Apply PAM shim to quickshell for non-NixOS PAM compatibility
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

  home.activation.maskConflictingServices = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Mask waybar and swaync services to prevent conflicts with noctalia
    $DRY_RUN_CMD mkdir -p $HOME/.config/systemd/user
    $DRY_RUN_CMD ln -sf /dev/null $HOME/.config/systemd/user/waybar.service
    $DRY_RUN_CMD ln -sf /dev/null $HOME/.config/systemd/user/swaync.service
    $DRY_RUN_CMD ${pkgs.systemd}/bin/systemctl --user daemon-reload || true
  '';

  systemd.user.services.swayidle = lib.mkIf config.desktops.addons.swayidle.enable (
    let
      shimmedQuickshell = config.lib.pamShim.replacePam pkgs.quickshell;
    in
    {
      Unit = {
        After = lib.mkForce [
          "graphical-session.target"
          "niri-env-setup.service"
        ];
      };
      Service = {
        ExecStart = lib.mkForce ''
          ${pkgs.swayidle}/bin/swayidle -w \
            timeout 300 '${shimmedQuickshell}/bin/qs ipc --newest call lockScreen lock' \
            timeout 330 'niri msg action power-off-monitors' \
              resume 'niri msg action power-on-monitors' \
            timeout 1800 '${pkgs.systemd}/bin/systemctl suspend' \
            before-sleep '${pkgs.systemd}/bin/loginctl lock-session'
        '';
      };
    }
  );

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

  fonts.fontconfig.enable = true;

  xdg = {
    mimeApps.defaultApplications = lib.mkForce {
      "text/html" = [ "google-chrome.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
      "x-scheme-handler/about" = [ "google-chrome.desktop" ];
      "x-scheme-handler/unknown" = [ "google-chrome.desktop" ];
    };

    configFile."fontconfig/conf.d/99-custom-fonts.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <!-- Default sans-serif font -->
        <match target="pattern">
          <test qual="any" name="family">
            <string>sans-serif</string>
          </test>
          <edit name="family" mode="assign">
            <string>Noto Sans</string>
          </edit>
        </match>

        <!-- Default serif font -->
        <match target="pattern">
          <test qual="any" name="family">
            <string>serif</string>
          </test>
          <edit name="family" mode="assign">
            <string>Source Serif</string>
          </edit>
        </match>

        <!-- Default monospace font -->
        <match target="pattern">
          <test qual="any" name="family">
            <string>monospace</string>
          </test>
          <edit name="family" mode="assign">
            <string>MonoLisa</string>
          </edit>
        </match>

        <!-- Monospace fallback chain -->
        <match target="pattern">
          <test name="family">
            <string>monospace</string>
          </test>
          <edit name="family" mode="append">
            <string>Symbols Nerd Font</string>
          </edit>
        </match>

        <match target="pattern">
          <test name="family">
            <string>monospace</string>
          </test>
          <edit name="family" mode="append">
            <string>DejaVu Sans Mono</string>
          </edit>
        </match>

        <!-- Sans-serif fallback chain -->
        <match target="pattern">
          <test name="family">
            <string>sans-serif</string>
          </test>
          <edit name="family" mode="append">
            <string>DejaVu Sans</string>
          </edit>
        </match>

        <match target="pattern">
          <test name="family">
            <string>sans-serif</string>
          </test>
          <edit name="family" mode="append">
            <string>Symbols Nerd Font</string>
          </edit>
        </match>

        <!-- Force emoji rendering -->
        <match target="pattern">
          <test name="family">
            <string>emoji</string>
          </test>
          <edit name="family" mode="assign">
            <string>Noto Color Emoji</string>
          </edit>
        </match>
      </fontconfig>
    '';
  };

  cli.tools.git = {
    allowedSigners = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUF0LHH63pGkd1m7FGdbZirVXULDS5WSDzerJ0sskoq haseeb.majid@nala.money";
    email = "haseeb.majid@nala.money";
  };

  nixicle.user = {
    enable = true;
    name = "haseebmajid";
  };

  home.stateVersion = "23.11";
}
