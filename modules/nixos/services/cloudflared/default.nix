{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.cloudflared;
in {
  options.services.nixicle.cloudflared = {
    enable = mkEnableOption "Enable The cloudflared (tunnel) service";
  };

  config = mkIf cfg.enable {
    sops.secrets.cloudflared = {
      sopsFile = ../secrets.yaml;
      owner = "cloudflared";
    };

    services = {
      cloudflared = {
        enable = true;
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            credentialsFile = config.sops.secrets.cloudflared.path;
            default = "http_status:404";
          };
        };
      };
    };
  };
}
