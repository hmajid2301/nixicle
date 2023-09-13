{ pkgs, ... }: {
  imports = [
    ./notifications/mako.nix
    #./notifications/swaync.nix
    ./launchers/rofi.nix
    ./launchers/wofi.nix

    ./gtk.nix
    ./gammastep.nix
    ./kanshi.nix
    ./swaylock.nix
    ./wlogout.nix
    ./waybar
    ./eww.nix
    #./xdg.nix
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
  };

  home.packages = with pkgs; [
    mplayer
    celluloid
    via
    mtpfs
    jmtpfs
    brightnessctl
    xdg-utils
    nautilus-open-any-terminal
    gnome.sushi
    gnome.nautilus
    gnome.gnome-disk-utility
    gnome.totem
    gnome.eog
    gnome.gvfs
    wl-clipboard
    pamixer
    playerctl
    sway-contrib.grimshot
    swaybg

    nwg-displays
  ];
}
