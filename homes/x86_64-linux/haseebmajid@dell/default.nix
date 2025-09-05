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

  stylix.enable = lib.mkForce false;
  stylix.autoEnable = lib.mkForce false;
  stylix.targets.gnome.enable = lib.mkForce false;
  stylix.targets.gnome.useWallpaper = lib.mkForce false;

  home = {
    # sessionVariables = {
    #   DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    # };

    packages = with pkgs; [
      semgrep
      pre-commit

      # INFO: Packages stylix usually installs but doesn't work with gnome 46 at the moment.
      # So we are installing them here and we will manually set them.
      pkgs.nixicle.monolisa
      pkgs.noto-fonts-emoji
      screensharing
      nwg-displays
      (lib.hiPrio (config.lib.nixGL.wrap totem))
    ];
  };

  sops.defaultSymlinkPath = lib.mkForce "/run/user/1001/secrets";
  sops.defaultSecretsMountPoint = lib.mkForce "/run/user/1001/secrets.d";

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

  xdg.configFile."environment.d/envvars.conf".text = ''
    PATH="$PATH:/home/haseebmajid/.nix-profile/bin"
  '';

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
