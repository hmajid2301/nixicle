{ config, pkgs, lib, ... }:

let
  hostname = "orange";
in
{
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };

    "/data" = {
      device = "/dev/sda";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };

  networking = {
    hostName = hostname;
  };

  nix.settings.trusted-users = [ hostname ];

  users = {
    #mutableUsers = false;
    users."${hostname}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      password = hostname;
      openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMxe8kDCJa6xcAM9WE8c5amGG+2secXmnof7vlmAq1Da hello@haseebmajid.dev" ];
    };
  };

  hardware.enableRedistributableFirmware = true;
  system.stateVersion = "23.11";
}
