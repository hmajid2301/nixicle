# SMB server for the migrated NAS.
# Observed TrueNAS smb4.conf [main] share:
#   path = /mnt/main/main
#   vfs objects = streams_xattr shadow_copy_zfs ixnas zfs_core io_uring
#   fruit:metadata=stream, fruit:resource=stream, smb3 directory leases = no
#   workgroup = WORKGROUP ; netbios name = truenas
#
# NOTE: `vfs_fruit` must be listed BEFORE `streams_xattr` in `vfs objects`
# (Samba requirement) — the earlier `streams_xattr fruit` ordering was wrong.
{ ... }:
{
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server string" = "nas";
        "server smb encrypt" = "default";
        "fruit:nfs_aces" = "no";
        "fruit:zero_file_id" = "no";
        "smb3 directory leases" = "no";
      };
      main = {
        path = "/mnt/main/main";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        # Files created via SMB inherit the shared `media` group (gid 3000),
        # matching the recovered TrueNAS ownership.
        "force group" = "media";
        "create mask" = "0664";
        "directory mask" = "2775";
        "valid users" = "@media";
        "fruit:metadata" = "stream";
        "fruit:resource" = "stream";
        "vfs objects" = "fruit streams_xattr";
      };
    };
  };

  # SMB is password-based and `smbpasswd` is stateful. Enable the SOPS-backed
  # oneshot below once `hosts/nas/secrets.yaml` exists with `smb_haseeb_password`
  # (plaintext SMB password). It runs `smbpasswd` on activation so the password
  # never lives in the Nix store. Left commented so the build stays green until
  # the secret is created.
  #
  # sops.secrets.smb_haseeb_password = { };
  # systemd.services.smb-set-passwords = {
  #   description = "Provision Samba passwords from SOPS";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "samba-smbd.service" ];
  #   serviceConfig.Type = "oneshot";
  #   script = ''
  #     pw=$(cat ${config.sops.secrets.smb_haseeb_password.path})
  #     printf '%s\n%s\n' "$pw" "$pw" | ${pkgs.samba}/bin/smbpasswd -s -a haseeb
  #   '';
  # };
}
