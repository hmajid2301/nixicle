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
    resumeDevice = "/dev/disk/by-uuid/ec9f42c1-12b4-43e9-9469-504eac0dc463";
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;

    # Setup keyfile
    initrd.secrets = {
      "/crypto_keyfile.bin" = null;
    };

    # Enable swap on luks
    initrd.luks.devices."luks-ceed8a20-b881-418e-9d46-006127d1d2d0".device = "/dev/disk/by-uuid/ceed8a20-b881-418e-9d46-006127d1d2d0";
    initrd.luks.devices."luks-ceed8a20-b881-418e-9d46-006127d1d2d0".keyFile = "/crypto_keyfile.bin";
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
