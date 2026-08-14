{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.niri.nixosModules.niri ];
  home-manager.sharedModules = lib.mkForce [ ];
  nixpkgs.overlays = [
    inputs.niri.overlays.niri
    inputs.noctalia-qs.overlays.default
  ];

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
