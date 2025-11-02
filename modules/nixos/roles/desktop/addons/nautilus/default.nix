{ config, lib, pkgs, ... }:
with lib;
with lib.nixicle;
let cfg = config.roles.desktop.addons.nautilus;
in {
  options.roles.desktop.addons.nautilus = with types; {
    enable = mkBoolOpt false "Whether to enable the gnome file manager.";
  };

  config = mkIf cfg.enable {
    services.gvfs.enable = true;
    services.udisks2.enable = true;

    environment = {
      sessionVariables = {
        NAUTILUS_EXTENSION_DIR =
          "${config.system.path}/lib/nautilus/extensions-4";
        NAUTILUS_4_EXTENSION_DIR =
          "${config.system.path}/lib/nautilus/extensions-4";
        GST_PLUGIN_SYSTEM_PATH_1_0 =
          lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0"
          (with pkgs.gst_all_1; [
            gst-plugins-good
            gst-plugins-bad
            gst-plugins-ugly
            gst-libav
          ]);
      };

      pathsToLink = [ "/share/nautilus-python/extensions" ];

      systemPackages = with pkgs; [
        ffmpegthumbnailer # thumbnails
        gst_all_1.gst-libav # thumbnails
        gdk-pixbuf # image thumbnails
        webp-pixbuf-loader # webp thumbnails
        nautilus-open-any-terminal
        nautilus-python
      ];
    };

    snowfallorg.users.${config.user.name}.home.config = {
      dconf.settings = {
        "org/gnome/nautilus/preferences" = {
          show-image-thumbnails = "always"; # Show thumbnails for all locations (local + remote)
          thumbnail-limit = 10; # Maximum allowed value (0-10 range)  
          show-directory-item-counts = "always";
          executable-text-activation = "ask";
          always-use-location-entry = false;
          default-folder-viewer = "icon-view";
          thumbnail-cache-time = 30; # Cache thumbnails for 30 days
        };
        "org/gnome/desktop/thumbnailers" = {
          disable-all = false;
        };
        # Ensure all thumbnailer types are enabled
        "org/gnome/desktop/thumbnailers/gstreamer" = {
          enable = true;
        };
        "org/gnome/desktop/thumbnailers/gdk-pixbuf" = {
          enable = true;
        };
        "org/gnome/desktop/thumbnailers/ffmpegthumbnailer" = {
          enable = true;
        };
        "org/gnome/desktop/privacy" = { 
          remember-recent-files = false;
          disable-camera = false;
          disable-microphone = false;
        };
        "com/github/stunkymonkey/nautilus-open-any-terminal" = {
          terminal = "ghostty";
        };
      };
    };
  };
}
