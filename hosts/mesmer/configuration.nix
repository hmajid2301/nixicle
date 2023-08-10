{ inputs, pkgs, ... }: {
  imports = [
    inputs.nix-gaming.nixosModules.default
    inputs.hyprland.nixosModules.default

    ./hardware-configuration.nix
    ./users/haseeb

    ../../nixos/global

    ../../nixos/optional/greetd.nix
    ../../nixos/optional/quietboot.nix

    ../../nixos/optional/docker.nix
    ../../nixos/optional/fonts.nix
    ../../nixos/optional/mullvad.nix
    ../../nixos/optional/pipewire.nix

    ../../nixos/optional/thunderbolt.nix
    ../../nixos/optional/opengl.nix
    ../../nixos/optional/vfio.nix
    ../../nixos/optional/gaming.nix

    #../../nixos/optional/attic.nix
    ../../nixos/optional/backup.nix
    #../nixos/optional/grub.nix
    #../nixos/optional/wireless.nix
    #../../nixos/optional/ephemeral.nix
  ];

  # Enable networking
  networking = {
    networkmanager = {
      enable = true;
    };
    hostName = "mesmer";
  };

  # Enable CUPS to print documents.
  # TODO: global
  services.printing.enable = true;
  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.pcscd.enable = true;
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
        device = "/dev/disk/by-uuid/0c07218e-5df9-4312-b0da-06b5881c1236";
        preLVM = true;
      };
    };
    resumeDevice = "/dev/disk/by-label/swap";
    kernelPackages = pkgs.linuxPackages_latest;
  };


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
