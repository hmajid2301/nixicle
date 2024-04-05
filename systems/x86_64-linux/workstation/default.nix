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
    vpn.enable = lib.mkForce false;
    virtualisation.kvm.enable = true;
    virtualisation.podman.enable = true;
  };

  suites = {
    gaming.enable = true;
    desktop = {
      enable = true;
      addons = {
        hyprland.enable = true;
      };
    };
  };

  networking.hostName = "workstation";

  swapDevices = [{device = "/swap/swapfile";}];

  boot = {
    kernelParams = [
      "resume_offset=533760"
    ];
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    resumeDevice = "/dev/disk/by-label/nixos";

    initrd.systemd.enable = true;
  };

  system.stateVersion = "23.11";
}
