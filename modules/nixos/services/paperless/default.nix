{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.services.nixicle.paperless;
in {
  options.services.nixicle.paperless = {
    enable = mkEnableOption "Enable the paperless service";
  };

  config = mkIf cfg.enable {
    users.users.${config.services.paperless.user}.extraGroups = ["media"];

    sops.secrets.paperless_pass = {
      sopsFile = ../secrets.yaml;
    };

    sops.secrets.paperless = {
      sopsFile = ../secrets.yaml;
    };

    systemd.services.paperless-web = {
      serviceConfig = {
        EnvironmentFile = [config.sops.secrets.paperless.path];
      };
      after = ["postgresql.service"];
    };

    services = {
      paperless = {
        enable = true;
        mediaDir = "/mnt/share/haseeb/homelab/paperless/media";
        passwordFile = config.sops.secrets.paperless_pass.path;

        settings = {
          PAPERLESS_DBHOST = "/run/postgresql";
        };
      };

      cloudflared = {
        enable = true;
        tunnels = {
          "ec0b6af0-a823-4616-a08b-b871fd2c7f58" = {
            ingress = {
              "paperless.haseebmajid.dev" = "http://localhost:28981";
            };
          };
        };
      };

      postgresql = {
        ensureDatabases = ["paperless"];
        ensureUsers = [
          {
            name = "paperless";
            ensureDBOwnership = true;
          }
        ];
      };
    };
  };
}
