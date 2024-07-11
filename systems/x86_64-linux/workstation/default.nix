{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  services = {
    virtualisation.kvm.enable = true;
    hardware.openrgb.enable = true;
  };

  roles = {
    gaming.enable = true;
    desktop = {
      enable = true;
      addons = {
        hyprland.enable = true;
      };
    };
  };

  environment.systemPackages = with pkgs;
  with pkgs.nixicle; [
    lm_sensors
  ];

  boot = {
    kernelModules = ["k10temp"];
    kernelParams = [
      "resume_offset=533760"
    ];
    blacklistedKernelModules = [
      "ath12k_pci"
      "ath12k"
    ];

    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}
