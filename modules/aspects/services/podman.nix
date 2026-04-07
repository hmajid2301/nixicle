{ den, ... }:
{
  den.aspects.podman = {
    nixos = _: {
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          dockerSocket.enable = true;
          dockerCompat = true;
          defaultNetwork.settings.dns_enabled = true;
        };
      };

      networking.firewall.enable = true;
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
    };
  };
}
