{ config, ... }:
let
  inherit (config.lib.topology) mkConnection mkRouter;
in
{
  networks = {
    home = {
      name = "Home";
      cidrv4 = "192.168.1.0/24";
    };
    tailscale = {
      name = "Tailscale";
      cidrv4 = "100.64.0.0/10";
    };
  };

  nodes = {
    router = mkRouter "Linksys" {
      info = "Linksys0218";
      interfaceGroups = [ [ "lan" ] ];
      connections.lan = [
        (mkConnection "nas" "enp1s0")
        (mkConnection "vps" "ens3")
      ];
      interfaces.lan.network = "home";
    };

    nas.interfaces.tailscale0.network = "tailscale";
    vps.interfaces.tailscale0.network = "tailscale";
  };
}
