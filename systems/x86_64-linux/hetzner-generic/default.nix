{
  pkgs,
  lib,
  config,
  ...
}: {
  # Basic system configuration for Hetzner
  networking.hostName = "hetzner-nixos";
  
  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Enable DHCP for network configuration
  networking.useDHCP = lib.mkDefault true;

  # Basic firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Hetzner-specific: enable virtio drivers
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_scsi" "virtio_blk" "virtio_net" ];
  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];

  # Use systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
  ];

  # Enable nix flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Create a user (optional, can be configured during install)
  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Set a default password (change after install!)
    initialPassword = "nixos";
  };

  # Allow sudo without password for wheel group (for initial setup)
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.11";
}