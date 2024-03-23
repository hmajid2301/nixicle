{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.suites.guis;
in {
  options.suites.guis = {
    enable = mkEnableOption "Enable gnome adwaita gui applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kooha
      mission-center
      foliate
      helvum
      pavucontrol
      trayscale
      celeste

      fragments
      baobab
      gnome.gnome-power-manager
      gnome.sushi
      gnome.gnome-disk-utility
      gnome.totem
      celluloid
      gnome.gvfs
      loupe
      gnome-text-editor
      gnome-network-displays
      gnome-firmware

      gnome.nautilus
      ffmpegthumbnailer # thumbnails
      gnome.nautilus-python # enable plugins
      gst_all_1.gst-libav # thumbnails
      nautilus-open-any-terminal # terminal-context-entry
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
