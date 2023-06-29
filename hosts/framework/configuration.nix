{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.hardware.nixosModules.framework-12th-gen-intel

    ./hardware-configuration.nix
    ./users/haseeb

    ../../nixos/global
    ../../nixos/optional/backup.nix
    ../../nixos/optional/fingerprint.nix
    ../../nixos/optional/gamemode.nix
    ../../nixos/optional/pipewire.nix
    ../../nixos/optional/greetd.nix
    ../../nixos/optional/quietboot.nix
    #../nixos/optional/grub.nix
    ../../nixos/optional/mullvad.nix
    #../nixos/optional/wireless.nix
  ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

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

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.luks.devices = {
      root = {
        device = "/dev/disk/by-uuid/c64e5b76-65de-44a6-9cf8-b893cfab54e2";
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
