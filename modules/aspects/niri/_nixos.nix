{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.niri.nixosModules.niri
    inputs.noctalia-greeter.nixosModules.default
  ];

  home-manager.sharedModules = lib.mkForce [ ];
  nixpkgs.overlays = [
    inputs.niri.overlays.niri
  ];

  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
  };
  users.groups.greeter = { };

  services.logind = {
    lidSwitch = lib.mkDefault "ignore";
    lidSwitchExternalPower = lib.mkDefault "ignore";
    lidSwitchDocked = lib.mkDefault "ignore";
  };

  programs.noctalia.recommendedServices.enable = lib.mkDefault true;
  services.power-profiles-daemon.enable = lib.mkDefault true;

  users.groups.battery_ctl = lib.mkIf config.services.power-profiles-daemon.enable { };
  services.udev.extraRules = lib.mkIf config.services.power-profiles-daemon.enable ''
    ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", RUN+="${pkgs.coreutils}/bin/chgrp battery_ctl /sys%p/charge_control_end_threshold", RUN+="${pkgs.coreutils}/bin/chmod 0664 /sys%p/charge_control_end_threshold"
  '';

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
      brightnessctl
      ffmpegthumbnailer
      gst_all_1.gst-libav
      gdk-pixbuf
      webp-pixbuf-loader
      nautilus-open-any-terminal
      nautilus-python
      gvfs
      nfs-utils
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
  services.gnome.evolution-data-server.enable = true;
  programs.dconf.enable = true;
  services = {
    gvfs.enable = true;
    udisks2.enable = true;
  };
}
