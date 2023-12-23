{ pkgs, config, inputs, lib, ... }: {
  imports = [
    ./gtk.nix
    ./gammastep.nix
    ./kanshi.nix
    ./swaylock.nix
    ./waybar
    ./wlogout.nix
    ./eww.nix
    ./scripts.nix
    ./xdg.nix

    ./notifications/swaync
    ./launchers/rofi.nix

  ];

  home.sessionVariables = rec {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";

    # TODO: move to xdg file maybe
    HISTFILE = lib.mkForce "$XDG_STATE_HOME/bash/history";
    GNUPGHOME = lib.mkForce "$XDG_DATA_HOME/gnupg";
    GTK2_RC_FILES = lib.mkForce "$XDG_CONFIG_HOME/gtk-2.0/gtkrc";
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

    networkmanagerapplet
    inputs.nwg-displays.packages."${pkgs.system}".default
  ];
}
