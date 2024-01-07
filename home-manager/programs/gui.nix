{pkgs, ...}: {
  home.packages = with pkgs; [
    kooha
    mission-center
    foliate
    helvum
    pavucontrol
    pika-backup

    baobab
    gnome.gnome-power-manager
    gnome.sushi
    gnome.nautilus
    gnome.gnome-disk-utility
    gnome.totem
    gnome.gvfs
    loupe
    gnome-text-editor
    gnome-firmware
  ];
}
