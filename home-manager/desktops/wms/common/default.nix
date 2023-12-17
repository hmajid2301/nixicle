{ pkgs, inputs, ... }: {
  imports = [
    ./gtk.nix
    ./gammastep.nix
    ./kanshi.nix
    ./swaylock.nix
    ./waybar.nix
    ./wlogout.nix
    ./eww.nix
    ./scripts.nix
    ./xdg.nix

    ./notifications/swaync.nix
    ./launchers/rofi.nix

  ];

  home.sessionVariables = {
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
    gnome.sushi
    gnome.nautilus
    gnome.gnome-disk-utility
    gnome.totem
    loupe
    gnome.gvfs
    gnome-text-editor
    wl-clipboard
    pamixer
    playerctl
    sway-contrib.grimshot

    networkmanagerapplet
    inputs.nwg-displays.packages."${pkgs.system}".default
  ];
}
