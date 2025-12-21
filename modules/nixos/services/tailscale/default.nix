{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.tailscale;
in
{
  options.services.nixicle.tailscale = {
    enable = mkEnableOption "Enable tailscale";
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;

    # INFO: https://github.com/tailscale/tailscale/issues/4432#issuecomment-1112819111
    networking.firewall.checkReversePath = "loose";
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          "/var/lib/tailscale"
        ];
      };
    };
  };
}
