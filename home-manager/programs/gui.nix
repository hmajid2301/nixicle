{pkgs, ...}: {
  home.packages = with pkgs; [
    kooha
    mission-center
    foliate
    helvum
    pavucontrol
    pika-backup
    read-it-later
    trayscale

    fragments
    baobab
    gnome.gnome-power-manager
    gnome.sushi
    gnome.nautilus
    gnome.gnome-disk-utility
    gnome.totem
    gnome.gvfs
    loupe
    gnome-text-editor
    gnome-network-displays
    gnome-firmware
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
}
