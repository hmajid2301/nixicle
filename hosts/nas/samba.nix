# SMB server for the migrated NAS.
# Observed TrueNAS smb4.conf [main] share:
#   path = /mnt/main/main
#   vfs objects = streams_xattr ... (fruit:metadata=stream, fruit:resource=stream)
#   smb3 directory leases = no
#   workgroup = WORKGROUP ; netbios name = truenas
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
        # Fruit/streams_xattr for macOS compatibility, like the TrueNAS config.
        "fruit:nfs_aces" = "no";
        "fruit:zero_file_id" = "no";
        "smb3 directory leases" = "no";
      };
      main = {
        path = "/mnt/main/main";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "fruit:metadata" = "stream";
        "fruit:resource" = "stream";
        "vfs objects" = "streams_xattr fruit";
      };
    };
  };
}