{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.security.nixicle.firewall;
in
{
  options.security.nixicle.firewall = {
    enable = mkEnableOption "Enable firewall with basic rules";
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      enable = true;
      allowPing = true;

      allowedTCPPorts = [ ];
      allowedUDPPorts = mkIf config.roles.desktop.enable [
        5353  # mDNS
      ];

      trustedInterfaces = [ "lo" ]
        ++ (optional config.services.nixicle.tailscale.enable "tailscale0");

      interfaces = {
        "wl+" = mkIf config.roles.desktop.enable {
          allowedUDPPorts = [ 5353 ];
        };
        "en+" = mkIf config.roles.desktop.enable {
          allowedUDPPorts = [ 5353 ];
        };
      };
    };

    networking.nftables.enable = false;
  };
}
