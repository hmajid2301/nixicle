{ inputs, pkgs, ... }: {
  imports = [
    inputs.hardware.nixosModules.framework-12th-gen-intel
    inputs.hyprland.nixosModules.default
    inputs.disko.nixosModules.disko

    ./hardware-configuration.nix
    ./users/haseeb

    ../../nixos/global
    ../../nixos/optional/backup.nix
    ../../nixos/optional/fingerprint.nix
    ../../nixos/optional/opengl.nix
    ../../nixos/optional/thunderbolt.nix
    ../../nixos/optional/docker.nix
    ../../nixos/optional/fonts.nix
    ../../nixos/optional/pipewire.nix
    ../../nixos/optional/greetd.nix
    ../../nixos/optional/quietboot.nix
    ../../nixos/optional/mullvad.nix
    ../../nixos/optional/grub.nix

    #../nixos/optional/wireless.nix
    #../../nixos/optional/ephemeral.nix
  ];

  # Enable networking
  networking = {
    networkmanager = {
      enable = true;
    };
    hostName = "framework";
  };

  # Enable CUPS to print documents.
  # TODO: global
  services.printing.enable = true;
  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.udev.packages = with pkgs; [ yubikey-personalization ];
  services.udisks2.enable = true;
  services.dbus.enable = true;
  programs.dconf.enable = true;

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "daily";
    flake = "gitlab:hmajid2301/dotfiles";
    flags = [
      "--refresh"
      "--recreate-lock-file"
      "--commit-lock-file"
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
