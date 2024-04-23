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

  boot = {
    kernelParams = [
      "resume_offset=533760"
      "mem_sleep_default=deep"
    ];
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  systemd.sleep.extraConfig = ''
    [Sleep]
    HibernateMode=shutdown
    SuspendState=mem # suspend2idle is buggy :(
  '';

  system.stateVersion = "23.11";
}
