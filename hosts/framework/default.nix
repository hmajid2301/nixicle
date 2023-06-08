{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.hardware.nixosModules.framework-12th-gen-intel

    ./hardware-configuration.nix

    ../common/global
    ../common/users/haseeb

    ../common/optional/fingerprint.nix
    ../common/optional/gamemode.nix
    #../common/optional/greetd.nix
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
    #../common/optional/wireless.nix
  ];

  # Backup for when I mess up hyprland config can resort back to gnome to fix
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  ## Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Enable networking
  networking = {
    networkmanager = {
      enable = true;
    };
    hostName = "framework";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
    kernelPackages = pkgs.linuxPackages_latest;

    # Setup keyfile
    initrd.secrets = {
      "/crypto_keyfile.bin" = null;
    };

    # Enable swap on luks
    initrd.luks.devices."luks-d9d5df49-3bc4-4d76-b63b-f3b018df19f7".device = "/dev/disk/by-uuid/d9d5df49-3bc4-4d76-b63b-f3b018df19f7";
    initrd.luks.devices."luks-d9d5df49-3bc4-4d76-b63b-f3b018df19f7".keyFile = "/crypto_keyfile.bin";
  };


  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "22.11";
}
