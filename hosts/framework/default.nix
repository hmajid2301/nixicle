{ inputs, outputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.hardware.nixosModules.framework-12th-gen-intel

    ./hardware-configuration.nix

    ../common/global
    ../common/users/haseeb

    #../common/optional/backup.nix
    ../common/optional/fingerprint.nix
    ../common/optional/gamemode.nix
    ../common/optional/pipewire.nix
    ../common/optional/greetd.nix
    ../common/optional/quietboot.nix
    ../common/optional/grub.nix
    ../common/optional/mullvad.nix
    ../common/optional/yubikey.nix
    #../common/optional/wireless.nix
  ];

  # Backup for when I mess up hyprland config can resort back to gnome to fix
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  ## Enable the KDE Plasma Desktop Environment.
  #services.xserver.displayManager.sddm.enable = true;
  #services.xserver.desktopManager.plasma5.enable = true;

  # Enable networking
  networking = {
    networkmanager = {
      enable = true;
    };
    hostName = "framework";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.fwupd.enable = true;
  # TODO: move to yubikey module


  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-uuid/05eaf550-1f58-4031-aaf8-762621cbd3ed";


    #initrd = {
    #  # Required to open the EFI partition and Yubikey
    #  kernelModules = ["vfat" "nls_cp437" "nls_iso8859-1" "usbhid"];
    #  
    #  luks = {
    #    yubikeySupport = true;
    #    
    #    devices."luks-770f6cc6-bfaa-4f49-aea1-e836cb68130e" = {
    #      device = "/dev/disk/by-uuid/770f6cc6-bfaa-4f49-aea1-e836cb68130e";
    #      
    #      yubikey = {
    #        slot = 2;
    #        twoFactor = false;
    #        gracePeriod = 30;
    #        keyLength = 64;
    #        saltLength = 16;
    #        
    #        storage = {
    #          device = "/dev/disk/by-uuid/0CF3-6C6D";
    #          fsType = "vfat";
    #          path = "/crypt-storage/default";
    #        };
    #      };
    #    };
    #    devices."luks-d9d5df49-3bc4-4d76-b63b-f3b018df19f7" = {
    #      device = "/dev/disk/by-uuid/d9d5df49-3bc4-4d76-b63b-f3b018df19f7";
    #      
    #      yubikey = {
    #        slot = 2;
    #        twoFactor = false;
    #        gracePeriod = 30;
    #        keyLength = 64;
    #        saltLength = 16;
    #        
    #        storage = {
    #          device = "/dev/disk/by-uuid/0CF3-6C6D";
    #          fsType = "vfat";
    #          path = "/crypt-storage/default";
    #        };
    #      };
    #    };
    #  };
    #};

    # Setup keyfile
    initrd.secrets = {
      "/crypto_keyfile.bin" = null;
    };

    # Enable swap on luks
    initrd.luks.devices."luks-d9d5df49-3bc4-4d76-b63b-f3b018df19f7".device = "/dev/disk/by-uuid/d9d5df49-3bc4-4d76-b63b-f3b018df19f7";
    initrd.luks.devices."luks-d9d5df49-3bc4-4d76-b63b-f3b018df19f7".keyFile = "/crypto_keyfile.bin";
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
  system.stateVersion = "22.11";
}
