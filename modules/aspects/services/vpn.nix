{ ... }:
{
  den.aspects.vpn = {
    nixos =
      { pkgs, ... }:
      {
        networking.wireguard.enable = true;
        services.tailscale.enable = true;
      };
  };
}
