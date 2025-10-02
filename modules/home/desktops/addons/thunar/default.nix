{ config, lib, pkgs, ... }:
with lib;
with lib.nixicle;
let cfg = config.desktops.addons.thunar;
in {
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
      ffmpegthumbnailer  # Video thumbnails
      libgsf            # Office document thumbnails  
      poppler           # PDF thumbnails
    ];
  };
}