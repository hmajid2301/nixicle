{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.roles.desktop.addons.nautilus;
in
{
  options.roles.desktop.addons.nautilus = with types; {
    enable = mkBoolOpt false "Whether to enable the gnome file manager.";
  };

  config = mkIf cfg.enable {
    services.gvfs.enable = true;
    services.udisks2.enable = true;

    environment = {
      sessionVariables = {
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

      pathsToLink = [ "/share/nautilus-python/extensions" ];

      systemPackages = with pkgs; [
        ffmpegthumbnailer
        gst_all_1.gst-libav
        gdk-pixbuf
        webp-pixbuf-loader
        nautilus-open-any-terminal
        nautilus-python
        gvfs
        nfs-utils
      ];
    };

    # NOTE: dconf settings for nautilus should be configured in home-manager
    # via the home modules (e.g., in the user's home configuration)
    # Example settings that should be in home-manager:
    # dconf.settings = {
    #   "org/gnome/nautilus/preferences" = {
    #     show-image-thumbnails = "always";
    #     thumbnail-limit = 10;
    #     ...
    #   };
    # };
  };
}
