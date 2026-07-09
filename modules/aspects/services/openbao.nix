{ ... }:
{
  den.aspects.openbao = {
    includes = [ ];
    persist.directories = [
      "/var/lib/openbao"
      "/var/log/openbao"
    ];
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        sops.secrets.openbao_static_seal_key = {
          owner = "openbao";
          group = "openbao";
          mode = "0400";
        };

        systemd = {
          tmpfiles.rules = [
            "d /var/log/openbao 0755 openbao openbao -"
          ];
          services.openbao.serviceConfig = {
            DynamicUser = lib.mkForce false;
            User = "openbao";
            Group = "openbao";
          };
        };

        services.openbao = {
          enable = true;
          package = pkgs.openbao;
          settings = {
            ui = true;
            api_addr = "http://127.0.0.1:8200";
            cluster_addr = "https://127.0.0.1:8201";
            seal.static = {
              current_key = "file://${config.sops.secrets.openbao_static_seal_key.path}";
              current_key_id = "primary";
            };
            listener.tcp = {
              type = "tcp";
              address = "127.0.0.1:8200";
              tls_disable = true;
            };
            storage.file.path = "/var/lib/openbao";
          };
        };


        users = {
          users.openbao = {
            isSystemUser = true;
            group = "openbao";
          };
          groups.openbao = { };
        };
      };
  };
}
