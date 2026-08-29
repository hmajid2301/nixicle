_: {
  den.aspects.vpn = {
    nixos = _: {
      networking.wireguard.enable = true;
      services.tailscale.enable = true;
    };
  };
}
