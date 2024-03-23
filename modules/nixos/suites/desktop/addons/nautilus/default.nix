{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.suites.desktop.addons.nautilus;
in {
  options.suites.desktop.addons.nautilus = with types; {
    enable = mkBoolOpt false "Whether to enable the gnome file manager.";
  };

  config = mkIf cfg.enable {
    services.gvfs.enable = true;
    services.udisks2.enable = true;

    snowfallorg.user.${config.user.name}.home.config = {
      dconf.settings = {
        "org/gnome/desktop/privacy" = {
          remember-recent-files = false;
        };
      };
    };

    environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      gst-libav
    ]);
  };
}
