{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.plausible;
in {
  options.services.nixicle.plausible = {
    enable = mkEnableOption "Enable the plausible service";
  };

  config = mkIf cfg.enable {
    sops.secrets.plausible_admin_password = {
      sopsFile = ../secrets.yaml;
    };

    sops.secrets.plausible_secret_keybase_file = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      clickhouse.enable = true;
      plausible = {
        enable = true;
        server = {
          baseUrl = "https://plausible.haseebmajid.dev";
          port = 8455;
          secretKeybaseFile = config.sops.secrets.plausible_secret_keybase_file.path;
        };
      };

      cloudflared = {
        enable = true;
        tunnels = {
          "0e845de6-544a-47f2-a1d5-c76be02ce153" = {
            ingress = {
              "plausible.haseebmajid.dev" = "http://localhost:8455";
            };
          };
        };
      };
    };
  };
}
