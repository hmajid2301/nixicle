{delib, ...}:
delib.host {
  name = "generic-iso";
  rice = "catppuccin";

  myconfig = {
    hosts.generic-iso = {
      type = "iso";
      isIso = true;
      system = "x86_64-linux";
    };
  };

  nixos = {pkgs, lib, config, myconfig, ...}: lib.mkIf (myconfig.host.name == "generic-iso") {
    # Generic system configuration for any hardware
    networking.hostName = lib.mkDefault "nixos-generic";

    # Enable SSH for remote access
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
      };
    };

    # Enable DHCP on all interfaces by default
    networking.useDHCP = lib.mkDefault true;

    # Basic firewall configuration
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };

    # Common kernel modules
    boot.initrd.availableKernelModules = [
      "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk"
      "nvme" "usbhid" "usb_storage" "sd_mod"
    ];

    # Support for various filesystems
    boot.supportedFilesystems = [ "ntfs" "exfat" "ext4" "btrfs" "xfs" ];

    # Set a unique hostId (required if ZFS support is enabled)
    networking.hostId = "12345678";

    # Dummy root filesystem for ISO
    fileSystems."/" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };

    # Use systemd-boot (UEFI) or GRUB (BIOS)
    boot.loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;

      # Fallback to GRUB for BIOS systems
      grub = {
        enable = lib.mkDefault false;
        device = lib.mkDefault "/dev/sda";
        useOSProber = true;
      };
    };

    # Hardware support packages
    hardware.enableRedistributableFirmware = true;
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # Basic packages for system administration
    environment.systemPackages = with pkgs; [
      vim
      git
      wget
      curl
      htop
      pciutils
      usbutils
      lshw
      parted
      gptfdisk
      cryptsetup
      ncdu
      tmux
    ];

    # Enable nix flakes
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Create a user for initial access
    users.users.nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      # Set a default password (change after install!)
      initialPassword = "nixos";
    };

    # Allow sudo without password for wheel group (for initial setup)
    security.sudo.wheelNeedsPassword = false;

    # Enable NetworkManager for easy network configuration
    networking.networkmanager.enable = true;

    # Enable some basic services
    services.acpid.enable = true;
    services.thermald.enable = lib.mkDefault true;

    # Console configuration
    console = {
      font = "Lat2-Terminus16";
      keyMap = lib.mkDefault "us";
    };

    # Time zone and locale
    time.timeZone = lib.mkDefault "UTC";
    i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

    system.stateVersion = "24.11";
  };
}
