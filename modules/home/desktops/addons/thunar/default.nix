{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.desktops.addons.thunar;
in
{
  options.desktops.addons.thunar = with types; {
    enable = mkBoolOpt false "Whether to enable Thunar file manager configuration.";
  };

  config = mkIf cfg.enable {
    # XDG file associations - set Thunar as default file manager
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "thunar.desktop";
        "application/x-directory" = "thunar.desktop";
      };
    };

    # Additional packages for enhanced thumbnail support
    home.packages = with pkgs; [
      ffmpegthumbnailer # Video thumbnails
      libgsf # Office document thumbnails
      poppler # PDF thumbnails
      gst_all_1.gst-libav # Additional video format support
      gdk-pixbuf # Image thumbnails
    ];

    # Configure tumbler (Thunar's thumbnail service) for better SMB performance
    xdg.configFile."tumbler/tumbler.rc".text = ''
      [General]
      LogLevel=1
      ThumbnailLifetime=2592000

      [Cache]
      CleanupInterval=86400

      [FFmpegThumbnailer]
      EnableThumbnailing=true
      MaxFileSize=1073741824
      WorkArounds=
    '';
  };
}
