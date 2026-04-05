{ den, ... }:
{
  den.aspects.tailscale = {
    nixos = { config, lib, ... }: {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "both";
      };
      services.resolved.enable = true;
      networking.firewall.checkReversePath = "loose";
      networking.firewall.trustedInterfaces = [ "tailscale0" ];
      environment.persistence."/persist".directories =
        lib.mkIf config.system.impermanence.enable [ "/var/lib/tailscale" ];
    };
  };
}
