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
  ];

  options.nixicle.desktop.greeter = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to use a display-manager/greeter session instead of direct autologin into Niri.";
    };

    command = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Command used by greetd for the configured desktop greeter session.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "greeter";
      description = "User used to launch the configured greeter session.";
    };
  };

  config = {
    home-manager.sharedModules = lib.mkForce [ ];
    nixpkgs.overlays = [
      inputs.niri.overlays.niri
    ];

    users = {
      users.greeter = lib.mkIf config.nixicle.desktop.greeter.enable {
        isSystemUser = true;
        group = "greeter";
      };
      groups.greeter = lib.mkIf config.nixicle.desktop.greeter.enable { };
      groups.battery_ctl = lib.mkIf config.services.power-profiles-daemon.enable { };
    };

    services = {
      logind.settings.Login = {
        HandleLidSwitch = lib.mkDefault "ignore";
        HandleLidSwitchExternalPower = lib.mkDefault "ignore";
        HandleLidSwitchDocked = lib.mkDefault "ignore";
      };
      power-profiles-daemon.enable = lib.mkDefault true;
      udev.extraRules = lib.mkIf config.services.power-profiles-daemon.enable ''
        ACTION=="add|change", SUBSYSTEM=="power_supply", KERNEL=="BAT*", RUN+="${pkgs.coreutils}/bin/chgrp battery_ctl /sys%p/charge_control_end_threshold", RUN+="${pkgs.coreutils}/bin/chmod 0664 /sys%p/charge_control_end_threshold"
      '';
      gnome.evolution-data-server.enable = true;
      gvfs.enable = true;
      udisks2.enable = true;
    };

    programs = {
      niri = {
        enable = true;
        package = pkgs.niri;
      };
      xwayland.enable = true;
      dconf.enable = true;
    };

    nix.settings = {
      extra-substituters = [ "https://niri.cachix.org" ];
      extra-trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
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
  };
}
