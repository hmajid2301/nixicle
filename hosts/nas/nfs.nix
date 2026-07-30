# NFS server exports for the migrated NAS.
#
# Observed TrueNAS export was only `/mnt/main/main`, but the nixicle client
# aspect (`nfs-nas`) also mounts `/mnt/main/main-encrypted` as `/mnt/homelab`,
# so both are exported here. The encrypted dataset must be unlocked+mounted
# for its export to serve data (see the cutover runbook).
{ ... }:
{
  services.nfs.server = {
    enable = true;
    exports = ''
      "/mnt/main/main" *(sec=sys,rw,anonuid=1000,anongid=1000,no_subtree_check,no_root_squash)
      "/mnt/main/main-encrypted" *(sec=sys,rw,anonuid=1000,anongid=1000,no_subtree_check,no_root_squash)
    '';
  };

  # Open the standard NFS port; rpcbind is enabled implicitly by services.nfs.server.
  networking.firewall.allowedTCPPorts = [ 2049 ];
  networking.firewall.allowedUDPPorts = [ 2049 ];
}
