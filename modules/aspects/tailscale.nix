{ den, lib, ... }:
{
  den.aspects.tailscale = {
    includes = [ (import ./services/_persist-forwarder.nix { inherit den lib; }) ];
    persist.directories = [ "/var/lib/tailscale" ];
    nixos = { config, lib, ... }: {
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
