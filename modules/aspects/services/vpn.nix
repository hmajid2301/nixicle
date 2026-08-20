{ ... }:
{
  den.aspects.vpn = {
    nixos =
      { ... }:
      {
        networking.wireguard.enable = true;
        services.tailscale.enable = true;
      };
  };
}
