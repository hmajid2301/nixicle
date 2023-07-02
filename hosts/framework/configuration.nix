{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.hardware.nixosModules.framework-12th-gen-intel
    inputs.nix-gaming.nixosModules.default
    inputs.hyprland.nixosModules.default

    ./hardware-configuration.nix
    ./users/haseeb

    ../../nixos/global
    ../../nixos/optional/backup.nix
    ../../nixos/optional/fingerprint.nix
    ../../nixos/optional/opengl.nix
    ../../nixos/optional/gaming.nix
    ../../nixos/optional/pipewire.nix
    ../../nixos/optional/greetd.nix
    ../../nixos/optional/quietboot.nix
    #../nixos/optional/grub.nix
    ../../nixos/optional/mullvad.nix
    #../nixos/optional/wireless.nix
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
  services.udev.packages = with pkgs; [ yubikey-personalization ];
  services.dbus.enable = true;
  programs.dconf.enable = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.luks.devices = {
      root = {
        device = "/dev/disk/by-uuid/fc112246-8ce0-47c7-95e5-106be34e9501";
        preLVM = true;
      };
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "daily";
    flags = [
      "--refresh"
      "--recreate-lock-file"
      "--commit-lock-file"
    ];
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
