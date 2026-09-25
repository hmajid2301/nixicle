_: {
  den.aspects.tailscale = {
    persist.directories = [ "/var/lib/tailscale" ];
    nixos = _: {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "both";
      };
      services.resolved.enable = true;
      networking.firewall.checkReversePath = "loose";
      networking.firewall.trustedInterfaces = [ "tailscale0" ];
    };
  };
}
