# NFS server exports for the migrated NAS.
#
# Observed TrueNAS export was only `/mnt/main/main`, but the nixicle client
# aspect (`nfs-nas`) also mounts `/mnt/main/main-encrypted` as `/mnt/homelab`,
# so both are exported here. The encrypted dataset must be unlocked+mounted
# for its export to serve data (see the cutover runbook).
#
# Clients mount `nas:` over NFSv4 requiring `tailscaled`, i.e. traffic flows
# over Tailscale and the source address is a Tailscale (100.64.0.0/10) IP, so
# exports are restricted to that CIDR instead of the wildcard `*`.
{
  config,
  lib,
  ...
}:
{
  services.nfs.server = {
    enable = true;
    exports = ''
      "/mnt/main/main" 100.64.0.0/10(sec=sys,rw,anonuid=1000,anongid=1000,no_subtree_check,no_root_squash)
      "/mnt/main/main-encrypted" 100.64.0.0/10(sec=sys,rw,anonuid=1000,anongid=1000,no_subtree_check,no_root_squash)
      "/mnt/main/main-encrypted/homelab" 100.64.0.0/10(sec=sys,rw,anonuid=1000,anongid=1000,no_subtree_check,no_root_squash)
    '';
  };

  # Open the standard NFS port; rpcbind is enabled implicitly by services.nfs.server.
  networking.firewall.allowedTCPPorts = [ 2049 ];
  networking.firewall.allowedUDPPorts = [ 2049 ];

  assertions = [
    {
      assertion = !lib.hasInfix "*(" config.services.nfs.server.exports;
      message = "NFS exports must not use the '*' wildcard client; restrict to the Tailscale CIDR (100.64.0.0/10).";
    }
  ];
}
