{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.programs.guis;
in {
  options.programs.guis = {
    enable = mkEnableOption "Enable gnome adwaita GUI applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      obsidian
      trayscale

      foliate
      pavucontrol

      baobab
      sushi
      gnome-disk-utility
      totem
      gvfs
      loupe
      gnome-text-editor
      gnome-firmware

      nautilus
      ffmpegthumbnailer # thumbnails
      nautilus-python # enable plugins
      gst_all_1.gst-libav # thumbnails
    ];

    xdg.configFile."com.github.johnfactotum.Foliate/themes/mocha.json".text = ''
      {
          "label": "Mocha",
          "light": {
          	"fg": "#999999",
          	"bg": "#cccccc",
          	"link": "#666666"
          },
          "dark": {
          	"fg": "#cdd6f4",
          	"bg": "#1e1e2e",
          	"link": "#E0DCF5"
          }
      }
    '';
  };
}
