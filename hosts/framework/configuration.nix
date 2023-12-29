{
  inputs,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
    ./disks.nix

    ../../nixos/global
    ../../nixos/users/haseeb.nix

    ../../nixos/optional/auto-upgrade.nix
    ../../nixos/optional/avahi.nix
    ../../nixos/optional/backup.nix
    ../../nixos/optional/docker.nix
    ../../nixos/optional/egpu.nix
    ../../nixos/optional/hardening.nix
    ../../nixos/optional/fonts.nix
    ../../nixos/optional/fingerprint.nix
    ../../nixos/optional/greetd.nix
    ../../nixos/optional/gaming.nix
    ../../nixos/optional/plymouth.nix
    ../../nixos/optional/pipewire.nix
    ../../nixos/optional/tailscale.nix
    ../../nixos/optional/tpm.nix
    ../../nixos/optional/tlp.nix
    ../../nixos/optional/virtualisation.nix
    ../../nixos/optional/vpn.nix
  ];

  networking = {
    hostName = "framework";
  };

  environment.systemPackages = [
    pkgs.headsetcontrol2
    pkgs.headset-charge-indicator
  ];
  services.udev.packages = [pkgs.headsetcontrol2];
  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt5ct";
  };

  swapDevices = [{device = "/swap/swapfile";}];
  boot = {
    kernelParams = [
      "amdgpu.sg_display=0"
      "resume_offset=533760"
    ];
    blacklistedKernelModules = ["hid-sensor-hub"];
    supportedFilesystems = lib.mkForce ["btrfs"];
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
