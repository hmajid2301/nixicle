{ config, pkgs, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  home-manager.users.haseeb = import ../../hosts/${config.networking.hostName}/home.nix;

  sops.secrets.haseeb-password = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };

  users.mutableUsers = false;
  users.users.haseeb = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "video"
      "audio"
    ] ++ ifTheyExist [
      "networkmanager"
      "libvirtd"
      "kvm"
      "docker"
      "podman"
      "git"
      "network"
      "wireshark"
      "i2c"
    ];

    passwordFile = config.sops.secrets.haseeb-password.path;
  };

  programs.fish.enable = true;
}
