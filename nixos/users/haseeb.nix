{
  config,
  pkgs,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  home-manager.users.haseeb = import ../../hosts/${config.networking.hostName}/home.nix;

  sops.secrets.haseeb-password = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };

  #users.mutableUsers = false;
  users.users.haseeb = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups =
      [
        "wheel"
        "video"
        "audio"
      ]
      ++ ifTheyExist [
        "networkmanager"
        "libvirtd"
        "kvm"
        "docker"
        "podman"
        "input"
        "git"
        "network"
        "wireshark"
        "i2c"
        "tss"
        "plugdev"
      ];

    #hashedPasswordFile = config.sops.secrets.haseeb-password.path;
    packages = [pkgs.home-manager];
  };

  programs.fish.enable = true;
}
