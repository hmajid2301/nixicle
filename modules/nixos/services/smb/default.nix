{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.smb;
in {
  options.services.nixicle.smb = {
    enable = mkEnableOption "Enable the smb server";
  };

  config = mkIf cfg.enable {
    # TODO: Fix this
    # fileSystems."/dev/nvme0n1p1" = {
    #   device = "/mnt/n1";
    #   options = ["bind"];
    # };
    #
    # fileSystems."/dev/nvme2n1p1" = {
    #   device = "/mnt/n2";
    #   options = ["bind"];
    # };

    services = {
      samba-wsdd = {
        enable = true;
        openFirewall = true;
      };

      samba = {
        enable = true;
        openFirewall = true;
        nmbd.enable = true;
        winbindd.enable = true;
        settings = {
          global = {
            "hosts allow" = "192.168.1. 100.64.0.0/10 127.0.0.1 localhost";
            "bind interfaces only" = "yes";
            interfaces = "lo enp90s0 tailscale0";
            security = "user";
            "min protocol" = "SMB2";
            "browseable" = "yes";
            "guest ok" = "yes";
          };
          public = {
            "path" = "/mnt/n1";
            "guest ok" = "yes";
            "read only" = "no";
            "create mask" = "0755";
            "directory mask" = "0755";
          };
        };
      };
    };
  };
}
