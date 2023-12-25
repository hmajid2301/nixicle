{ pkgs, config, inputs, lib, ... }: {
  imports = [
    ./gtk.nix
    ./gammastep.nix
    ./kanshi.nix
    ./swaylock.nix
    ./waybar
    ./wlogout.nix
    ./eww.nix
    ./xdg.nix

    ./notifications/swaync
    ./launchers/rofi.nix

  ];

  home.sessionVariables = rec {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
  };

  home.packages = with pkgs; [
    mplayer
    mtpfs
    jmtpfs
    brightnessctl
    xdg-utils
    wl-clipboard
    pamixer
    playerctl
    sway-contrib.grimshot

    impression
    raider
    helvum
    gnome.gnome-font-viewer
    gnome.gnome-characters
    gnome.sushi
    gnome.nautilus
    gnome.gnome-disk-utility
    gnome.totem
    gnome.gucharmap
    gnome.gvfs
    gnome.gnome-logs
    loupe
    gnome-text-editor
    pavucontrol

    inputs.nwg-displays.packages."${pkgs.system}".default
  ];
}
