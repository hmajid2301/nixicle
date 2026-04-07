_:
{
  den.aspects.thunar = {
    homeManager =
      { pkgs, ... }:
      {
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "inode/directory" = "thunar.desktop";
            "application/x-directory" = "thunar.desktop";
          };
        };

        home.packages = with pkgs; [
          ffmpegthumbnailer
          libgsf
          poppler
          gst_all_1.gst-libav
          gdk-pixbuf
        ];

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
  };
}
