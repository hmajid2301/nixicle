{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.nfs;
in {
  options.services.nixicle.nfs = {
    enable = mkEnableOption "Enable the (mount) nfs drive";
  };

  config = mkIf cfg.enable {
    sops.secrets.nfs_smb_secrets = {
      sopsFile = ../secrets.yaml;
    };

    networking.firewall.allowedTCPPorts = [2049];

    services.nfs.server = {
      enable = true;
      exports = ''
        /exports     192.168.1.10(rw,fsid=0,no_subtree_check)          192.168.1.15(rw,fsid=0,no_subtree_check)
        /exports/n1  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
        /exports/n2  192.168.1.10(rw,nohide,insecure,no_subtree_check) 192.168.1.15(rw,nohide,insecure,no_subtree_check)
      '';
    };

    environment.systemPackages = with pkgs; [
      cifs-utils
      nfs-utils
    ];

    fileSystems."/mnt/nfs" = {
      device = "192.168.1.73:/volume1/Data";
      fsType = "nfs";
    };

    fileSystems."/mnt/share" = {
      device = "//192.168.1.73/Data/homelab";
      fsType = "cifs";
      options = let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in [
        "${automount_opts},credentials=${config.sops.secrets.nfs_smb_secrets.path}"
        "uid=root"
        "gid=media"
        "file_mode=0664"
        "dir_mode=0775"
      ];
    };
  };
}
