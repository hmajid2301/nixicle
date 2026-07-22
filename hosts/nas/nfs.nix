# NFS server export for the migrated NAS.
# Observed TrueNAS export:
#   "/mnt/main/main" *(sec=sys,rw,anonuid=1000,anongid=1000,no_subtree_check)
{ ... }:
{
  services.nfs.server = {
    enable = true;
    exports = ''
      "/mnt/main/main" *(sec=sys,rw,anonuid=1000,anongid=1000,no_subtree_check,no_root_squash)
    '';
  };

  # Open the standard NFS port; rpcbind is enabled implicitly by services.nfs.server.
  networking.firewall.allowedTCPPorts = [ 2049 ];
  networking.firewall.allowedUDPPorts = [ 2049 ];
}