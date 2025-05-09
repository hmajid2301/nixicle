{ config, lib, pkgs, ... }:
with lib;
with lib.nixicle;
let cfg = config.services.nixicle.smb;
in {
  options.services.nixicle.smb = {
    enable = mkEnableOption "Enable the smb server";
  };

  config = mkIf cfg.enable {
    services = {
      samba-wsdd = {
        enable = true;
        openFirewall = true;
      };

      samba = {
        enable = true;
        openFirewall = true;
        securityType = "user";
        nmbd.enable = true;
        winbindd.enable = true;
        settings = {
          global = {
            "hosts allow" = "192.168.1. 100.64.0.0/10 127.0.0.1 localhost";
            "bind interfaces only" = "yes";
            interfaces = "lo enp91s0 tailscale0";
            security = "user";
            "min protocol" = "SMB2";
            "browseable" = "yes";
            "guest account" = "nobody";
            "map to guest" = "bad user";
          };
          public = {
            "path" = "/mnt/n1";
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            "create mask" = "0644";
            "directory mask" = "0755";
            "force user" = "nixos";
            "force group" = "users";
          };
        };
      };
    };
  };
}
