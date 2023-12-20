{ inputs, pkgs, lib, ... }: {
  imports = [
    inputs.hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
    ./disks.nix

    ../../nixos/global
    ../../nixos/users/haseeb.nix

    ../../nixos/optional/auto-upgrade.nix
    ../../nixos/optional/auto-hibernate.nix
    ../../nixos/optional/avahi.nix
    ../../nixos/optional/backup.nix
    ../../nixos/optional/docker.nix
    ../../nixos/optional/fonts.nix
    ../../nixos/optional/fingerprint.nix
    ../../nixos/optional/greetd.nix
    ../../nixos/optional/gaming.nix
    ../../nixos/optional/quietboot.nix
    ../../nixos/optional/pipewire.nix
    ../../nixos/optional/tailscale.nix
    ../../nixos/optional/tpm.nix
    ../../nixos/optional/tlp.nix
    ../../nixos/optional/vfio.nix
    ../../nixos/optional/vpn.nix
  ];

  networking = {
    hostName = "framework";
  };

  environment.systemPackages = [
    pkgs.headsetcontrol2
    pkgs.headset-charge-indicator
  ];
  services.udev.packages = [ pkgs.headsetcontrol2 ];
  hardware.framework.amd-7040.preventWakeOnAC = true;
  boot.bootspec.enable = true;

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  swapDevices = [{ device = "/swap/swapfile"; }];
  boot = {
    kernelParams = [
      "mem_sleep_default=deep"
      "nvme.noacpi=1"
      "btusb.enable_autosuspend=n"
      "i915.enable_psr=0"
      "resume_offset=533760"
      "amdgpu.sg_display=0"
    ];
    blacklistedKernelModules = [ "hid-sensor-hub" ];
    supportedFilesystems = lib.mkForce [ "btrfs" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    resumeDevice = "/dev/disk/by-label/nixos";
    # lanzaboote = {
    #   enable = true;
    #   pkiBundle = "/etc/secureboot";
    # };
  };

  system.stateVersion = "23.11";
}
