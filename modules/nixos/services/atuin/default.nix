{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.atuin;
in
{
  options.services.nixicle.atuin = {
    enable = mkEnableOption "Enable atuin";
  };

  config = mkIf cfg.enable {
    services.atuin = {
      enable = true;
      openRegistration = true;
      maxHistoryLength = 99999999;
      port = 8890;
    };

    services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
      ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
        "atuin.haseebmajid.dev" = "http://localhost:8890";
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          "/var/lib/atuin"
        ];
      };
    };
  };
}
