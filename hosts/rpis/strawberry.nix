{ config, pkgs, lib, ... }:

let
  hostname = "strawberry";
in
{
  networking = {
    hostName = hostname;
  };

  nix.settings.trusted-users = [ hostname ];

  users = {
    users."${hostname}" = {
      isNormalUser = true;
      shell = pkgs.fish;
      extraGroups = [ "wheel" ];
      password = hostname;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMxe8kDCJa6xcAM9WE8c5amGG+2secXmnof7vlmAq1Da hello@haseebmajid.dev"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHiXSCUnfGG1lxQW470+XBiDgjyYOy5PdHdXsmpraRei haseeb.majid@imaginecurve.com"
      ];
    };
  };

}
