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
    killall -e xdg-desktop-portal-hyprland
    killall -e xdg-desktop-portal-wlr
    killall xdg-desktop-portal
    /usr/libexec/xdg-desktop-portal-hyprland &
    sleep 2
    /usr/libexec/xdg-desktop-portal &
  '';
in
{
  nixGL = {
    inherit (inputs.nixgl) packages;
    defaultWrapper = "mesa";
  };

  programs = {
    firefox.package = config.lib.nixGL.wrap pkgs.firefox;
    ghostty.package = config.lib.nixGL.wrap pkgs.ghostty;
  };

  roles = {
    desktop.enable = true;
  };

  home = {
    sessionVariables = {
      DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    };

    packages = with pkgs; [
      semgrep
      pre-commit
      # screensharing
      # nwg-displays
      # (lib.hiPrio (config.lib.nixGL.wrap totem))
    ];
  };

  # desktops = {
  #   hyprland = {
  #     enable = true;
  #     execOnceExtras = [
  #       "warp-taskbar"
  #       "blueman-applet"
  #       "${screensharing}/bin/screensharing"
  #       "nm-applet"
  #     ];
  #   };
  #
  #   gnome.enable = true;
  # };

  xdg.configFile."environment.d/envvars.conf".text = ''
    PATH="$PATH:/home/haseebmajid/.nix-profile/bin"
  '';

  # cli.programs = {
  #   git = {
  #     allowedSigners = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOEtfQ0znAH8QyB4Z5FzRPa9iKkBhuriEpqyfoEkiv+ haseeb.majid@imaginecurve.com";
  #     email = "haseeb.majid@nala.money";
  #   };
  # };

  nixicle.user = {
    enable = true;
    name = "haseebmajid";
  };

  home.stateVersion = "23.11";
}
