{ ... }:
{
  den.aspects.openbao = {
    includes = [ ];
    persist.directories = [
      "/var/lib/openbao"
      "/var/log/openbao"
    ];
    backup.openbao = {
      paths = [ "/var/lib/openbao" ];
      backupPrepareCommand = ''
        systemctl stop openbao.service
      '';
      backupCleanupCommand = ''
        systemctl start openbao.service
      '';
    };
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "openbao";
          port = 8200;
          subdomain = "openbao";
          domain = "homelab.haseebmajid.dev";
          entryPoints = [ "websecure" ];
          certResolver = "letsencrypt";
        };

        sops = {
          secrets = {
            openbao_admin_password = { };
            openbao_static_seal_key = {
              owner = "openbao";
              group = "openbao";
              mode = "0400";
            };
          };
          templates."openbao-env".content = ''
            OPENBAO_ADMIN_PASSWORD=${config.sops.placeholder.openbao_admin_password}
            OPENBAO_STATIC_SEAL_KEY=${config.sops.placeholder.openbao_static_seal_key}
          '';
        };

        systemd = {
          tmpfiles.rules = [
            "d /var/log/openbao 0755 openbao openbao -"
          ];
          services.openbao.serviceConfig = {
            EnvironmentFile = config.sops.templates."openbao-env".path;
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
              current_key = "env://OPENBAO_STATIC_SEAL_KEY";
              current_key_id = "primary";
            };
            listener.tcp = {
              type = "tcp";
              address = "127.0.0.1:8200";
              tls_disable = true;
            };
            storage.file.path = "/var/lib/openbao";
            initialize = [
              {
                policy.request = [
                  {
                    add-admin-policy = {
                      operation = "update";
                      path = "sys/policies/acl/admin";
                      data.policy = ''
                        path "*" {
                          capabilities = ["create", "update", "read", "delete", "list", "scan", "sudo"]
                        }
                      '';
                    };
                  }
                ];
              }
              {
                identity.request = [
                  {
                    mount-userpass = {
                      operation = "update";
                      path = "sys/auth/userpass";
                      data = {
                        type = "userpass";
                        description = "Local userpass authentication";
                      };
                    };
                  }
                  {
                    userpass-add-admin = {
                      operation = "update";
                      path = "auth/userpass/users/admin";
                      data = {
                        password = {
                          eval_type = "string";
                          eval_source = "env";
                          env_var = "OPENBAO_ADMIN_PASSWORD";
                        };
                        token_policies = [ "admin" ];
                      };
                    };
                  }
                ];
              }
            ];
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
