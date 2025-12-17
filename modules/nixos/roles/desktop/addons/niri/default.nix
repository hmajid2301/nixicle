{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.roles.desktop.addons.niri;
in
{
  options.roles.desktop.addons.niri = with types; {
    enable = mkBoolOpt false "Enable or disable the niri window manager.";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      substituters = [ "https://niri.cachix.org" ];
      trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
    };

    programs.niri = {
      enable = true;
      # package = pkgs.niri-unstable.overrideAttrs (old: {
      #   doCheck = false;
      # });
      package = pkgs.niri-unstable;
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = with pkgs; [
      wl-clipboard
      slurp
      grim
      wf-recorder
      brightnessctl
    ];

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config.niri = {
        default = [ "gnome" ];
        # Use GNOME portal for screencasting (niri wiki recommendation)
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };
      xdgOpenUsePortal = true;
    };

    roles.desktop.addons.greetd.enable = true;
    roles.desktop.addons.nautilus.enable = true;
    programs.xwayland.enable = true;
    security.nixicle.polkit-gnome.enable = true;
    services.nixicle.evolution.enable = true;
  };
}
