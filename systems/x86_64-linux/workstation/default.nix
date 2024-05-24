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

  # TODO: move when working
  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  networking.hostName = "workstation";

  boot = {
    kernelParams = [
      "mem_sleep_default=deep"
      "resume_offset=533760"
    ];
    blacklistedKernelModules = [
      "ath12k_pci"
    ];

    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}
