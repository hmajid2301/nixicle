{ config, lib, pkgs, ... }:
with lib;
with lib.nixicle;
let cfg = config.desktops.addons.thunar;
in {
  options.desktops.addons.thunar = with types; {
    enable = mkBoolOpt false "Whether to enable Thunar file manager with thumbnail support.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Core Thunar packages
      xfce.thunar
      xfce.thunar-volman
      xfce.thunar-archive-plugin
      xfce.thunar-media-tags-plugin
      
      # Thumbnail generation service and plugins
      tumbler # Main thumbnail service for XFCE/Thunar
      
      # Video thumbnail support
      ffmpegthumbnailer
      
      # Image format support
      libgsf # Office document thumbnails
      poppler # PDF thumbnails
      freetype # Font thumbnails
      
      # Archive thumbnail support
      libarchive
      
      # Additional media support
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-libav
      
      # For SMB/CIFS support
      gvfs # Virtual filesystem support for SMB
    ];

    # Enable tumbler service for thumbnail generation
    services.tumbler.enable = true;

    # XDG file associations
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "thunar.desktop";
        "application/x-directory" = "thunar.desktop";
      };
    };

    # Thunar configuration
    dconf.settings = {
      "org/xfce/thunar" = {
        # Enable thumbnails for all files
        misc-thumbnail-mode = "THUNAR_THUMBNAIL_MODE_ALWAYS";
        misc-thumbnail-max-file-size = 1073741824; # 1GB limit
        
        # Show thumbnails in all view modes
        last-icon-view-zoom-level = "THUNAR_ZOOM_LEVEL_NORMAL";
        last-details-view-zoom-level = "THUNAR_ZOOM_LEVEL_SMALLER";
        
        # File manager preferences
        last-view = "ThunarIconView";
        last-location-bar = "ThunarLocationButtons";
        last-side-pane = "ThunarShortcutsPane";
        misc-single-click = false;
        misc-full-path-in-title = false;
        misc-folders-first = true;
        misc-show-delete-action = true;
      };
    };

    # Session variables for thumbnail support
    home.sessionVariables = {
      # Ensure tumbler can find all thumbnailer plugins
      TUMBLER_PLUGINS_PATH = "${pkgs.tumbler}/lib/tumbler-1/plugins";
    };

    # Create thumbnailer configuration for better SMB support
    xdg.configFile."tumbler/tumbler.rc".text = ''
      [General]
      # Enable all thumbnail generators
      Disabled=

      [Cache]
      # Thumbnail cache settings
      MaxFileSize=1073741824
      
      [ffmpeg-thumbnailer]
      # Video thumbnail settings
      MaxFileSize=1073741824
      FilmStripMode=false
      WorkaroundBugs=true
      SeekPercentage=10
      
      [pixbuf-thumbnailer]
      # Image thumbnail settings  
      MaxFileSize=1073741824
      
      [gst-thumbnailer]
      # GStreamer video thumbnail settings
      MaxFileSize=1073741824
    '';

    # Autostart tumbler service
    xdg.configFile."autostart/tumbler.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Tumbler
      Comment=Thumbnail generation service
      Exec=${pkgs.tumbler}/lib/tumbler-1/tumblerd
      Hidden=false
      NoDisplay=true
      X-GNOME-Autostart-Phase=Initialization
      X-GNOME-AutoRestart=true
      X-KDE-autostart-phase=1
    '';
  };
}