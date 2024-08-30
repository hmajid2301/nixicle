{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  services = {
    virtualisation.kvm.enable = true;
    hardware.openrgb.enable = true;
    nixicle.ollama.enable = true;
  };
  programs.coolercontrol.enable = true;

  roles = {
    gaming.enable = true;
    desktop = {
      enable = true;
      addons = {
        hyprland.enable = true;
      };
    };
  };

  boot = {
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
