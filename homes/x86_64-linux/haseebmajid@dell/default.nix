{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  screensharing = pkgs.writeScriptBin "screensharing" ''
    #!/usr/bin/env bash
    sleep 1
    killall -e xdg-desktop-portal-hyprland 2>/dev/null || true
    killall -e xdg-desktop-portal-wlr 2>/dev/null || true
    killall xdg-desktop-portal 2>/dev/null || true
    # Use NixOS paths instead of hardcoded /usr/libexec
    if command -v xdg-desktop-portal-hyprland >/dev/null 2>&1; then
      xdg-desktop-portal-hyprland &
    fi
    sleep 2
    if command -v xdg-desktop-portal >/dev/null 2>&1; then
      xdg-desktop-portal &
    fi
  '';
in
{
  nixGL = {
    inherit (inputs.nixgl) packages;
    defaultWrapper = "mesa";
  };

  programs = {
    firefox.package = config.lib.nixGL.wrap pkgs.firefox;
    # ghostty.package = config.lib.nixGL.wrap pkgs.ghostty;
  };

  roles = {
    desktop.enable = true;
  };

  home = {
    # sessionVariables = {
    #   DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    # };

    packages = with pkgs; [
      semgrep
      pre-commit
      bun

      # INFO: Packages stylix usually installs but doesn't work with gnome 46 at the moment.
      # So we are installing them here and we will manually set them.
      pkgs.nixicle.monolisa
      pkgs.noto-fonts-emoji
      pkgs.noto-fonts
      pkgs.source-serif
      pkgs.nerd-fonts.symbols-only
      pkgs.dejavu_fonts
      screensharing
      nwg-displays
      (lib.hiPrio (config.lib.nixGL.wrap totem))
    ];
  };

  # TODO: Don't hardcode UID - use dynamic resolution like: "/run/user/${toString config.users.users.${config.home.username}.uid}/secrets"
  # This breaks if user gets different UID on different systems
  sops.defaultSymlinkPath = lib.mkForce "/run/user/1003/secrets";
  sops.defaultSecretsMountPoint = lib.mkForce "/run/user/1003/secrets.d";

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
        "MonoLisa" # Primary font
        "Symbols Nerd Font" # Glyph fallback
        "Noto Color Emoji" # Emoji fallback
      ];

      theme = "catppuccin-mocha";

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
      keybind = [
        "ctrl+shift+plus=increase_font_size:1"
      ];
    };
  };

  desktops = {
    hyprland = {
      enable = true;
      execOnceExtras = [
        "warp-taskbar"
        "blueman-applet"
        "${screensharing}/bin/screensharing"
        "nm-applet"
      ];
    };

    # gnome.enable = true;
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

    configFile."environment.d/envvars.conf".text = ''
      PATH="$PATH:${config.home.homeDirectory}/.nix-profile/bin"
    '';

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

        <!-- Comprehensive fallback chain to prevent square blocks -->
        <match target="pattern">
          <edit name="family" mode="append">
            <string>Noto Sans</string>
          </edit>
        </match>

        <match target="pattern">
          <edit name="family" mode="append">
            <string>Noto Sans</string>
          </edit>
        </match>

        <match target="pattern">
          <edit name="family" mode="append">
            <string>Noto Color Emoji</string>
          </edit>
        </match>

        <match target="pattern">
          <edit name="family" mode="append">
            <string>Symbols Nerd Font</string>
          </edit>
        </match>

        <match target="pattern">
          <edit name="family" mode="append">
            <string>DejaVu Sans</string>
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

  cli.programs = {
    git = {
      allowedSigners = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDUF0LHH63pGkd1m7FGdbZirVXULDS5WSDzerJ0sskoq haseeb.majid@nala.money";
      email = "haseeb.majid@nala.money";
    };
  };

  nixicle.user = {
    enable = true;
    name = "haseebmajid";
  };

  home.stateVersion = "23.11";
}
