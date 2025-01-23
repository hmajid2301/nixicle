{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  roles = {
    server.enable = true;
  };

  services.nixicle = {
    traefik.enable = true;
    postgresql.enable = true;
    home-assistant.enable = true;
    adguard.enable = true;
    n8n.enable = true;
    logging.enable = true;
  };

  topology.self = {
    hardware.info = "S100";
  };

  boot = {
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "23.11";
}
