{ pkgs, config, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  #sops.secrets.haseeb_password = {
  #  sopsFile = ../../secrets.yaml;
  #  neededForUsers = true;
  #};

  home-manager.users.haseeb = import ../../../../home/haseeb/${config.networking.hostName}.nix;

  users.users.haseeb = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "haseeb";
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "networkmanager"
    ] ++ ifTheyExist [
      "docker"
      "podman"
      "git"
    ];
    #openssh.authorizedKeys.keys = [ (builtins.readFile ../../../../home/haseeb/ssh.pub) ];
    #passwordFile = config.sops.secrets.haseeb_password.path;
    packages = [ pkgs.home-manager ];
  };

  programs.fish.enable = true;
  services.geoclue2.enable = true;
  security.pam.services = {
    swaylock = { };
    login.u2fAuth = true;
    sudo.u2fAuth = true;
  };
}
