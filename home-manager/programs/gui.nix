{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    kooha
    mission-center
    foliate
    helvum
    pavucontrol
    pika-backup
    read-it-later
    trayscale
    piper
    celeste
    obsidian

    fragments
    baobab
    thunderbird
    gnome.gnome-power-manager
    gnome.sushi
    gnome.gnome-disk-utility
    gnome.totem
    celluloid
    clapper
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

  home.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
  ]);

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
}
