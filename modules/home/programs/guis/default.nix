{delib, ...}:
delib.module {
  name = "programs-guis";

  options.programs.guis = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  let
    cfg = config.programs.guis;
  in
  mkIf cfg.enable {
    # Add nautilus gsettings schemas to XDG_DATA_DIRS so gsettings can find them
    # This is required for Nautilus Preferences GUI to work properly
    xdg.systemDirs.data = [
      "${pkgs.nautilus}/share/gsettings-schemas/${pkgs.nautilus.name}"
    ];

    home.packages = with pkgs; [
      trayscale

      foliate
      pwvucontrol

      sushi
      gnome-disk-utility
      totem
      gvfs
      loupe

      obsidian

      nautilus
      ffmpegthumbnailer # thumbnails
      nautilus-python # enable plugins
      gst_all_1.gst-libav # thumbnails
    ];
  };
}
