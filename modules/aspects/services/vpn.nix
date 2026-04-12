{ ... }:
{
  den.aspects.vpn = {
    nixos =
      { pkgs, ... }:
      {
        networking.wireguard.enable = true;
        services.mullvad-vpn = {
          enable = true;
          package = pkgs.mullvad-vpn;
        };
        services.tailscale.enable = true;
      };
  };
}
