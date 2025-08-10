{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.guis;
in
{
  options.programs.guis = {
    enable = mkEnableOption "Enable gnome adwaita GUI applications";
  };

  config = mkIf cfg.enable {
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
