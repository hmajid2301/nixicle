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
    QT_QPA_PLATFORMTHEME = "gtk3";
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
    gnome.nautilus-python
    gnome.sushi
    gnome.nautilus
    gnome.gnome-disk-utility
    gnome.totem
    gnome.eog
    gnome.gvfs
    gnome-text-editor
    wl-clipboard
    pamixer
    playerctl
    sway-contrib.grimshot
    swaybg

    networkmanagerapplet
    inputs.nwg-displays.packages."${pkgs.system}".default
    nwg-look
  ];
}
