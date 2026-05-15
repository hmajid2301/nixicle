{ ... }:
{
  den.aspects.openbao = {
    includes = [ ];
    persist.directories = [
      "/var/lib/private/openbao"
      "/var/log/openbao"
      {
        directory = "/var/lib/openbao-proxy";
        user = "openbao-proxy";
        group = "openbao-proxy";
        mode = "0750";
      }
      "/etc/openbao"
    ];
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        sops = {
          secrets = {
            openbao_admin_password.sopsFile = ../../../hosts/framebox/secrets.yaml;
            spindle_role_id = {
              sopsFile = ../../../hosts/framebox/secrets.yaml;
              owner = "openbao-proxy";
            };
            spindle_secret_id = {
              sopsFile = ../../../hosts/framebox/secrets.yaml;
              owner = "openbao-proxy";
            };
          };
          templates."openbao-env".content = ''
            OPENBAO_ADMIN_PASSWORD=${config.sops.placeholder.openbao_admin_password}
          '';
        };

        systemd = {
          tmpfiles.rules = [
            "d /var/log/openbao 0755 openbao openbao -"
            "d /etc/openbao 0755 root root -"
            "f /etc/openbao/unseal-key 0644 root root - wsCAnl5+faMlNFeAmorMVJao+rhkI1upJw+PAUFoAr0="
          ];
          services = {
            openbao.serviceConfig.EnvironmentFile = config.sops.templates."openbao-env".path;
            openbao-proxy = {
              description = "OpenBao Proxy with Auto-Auth";
              wantedBy = [ "multi-user.target" ];
              after = [
                "network.target"
                "openbao.service"
              ];
              preStart = ''
                mkdir -p /var/lib/openbao-proxy
                mkdir -p /etc/openbao
                chown openbao-proxy:openbao-proxy /var/lib/openbao-proxy
              '';
              serviceConfig = {
                ExecStart = "${pkgs.openbao}/bin/bao proxy -config=${pkgs.writeText "openbao-proxy.hcl" ''
                  vault {
                    address = "http://127.0.0.1:8200"
                    retry { num_retries = 5 }
                  }
                  auto_auth {
                    method {
                      type = "approle"
                      config = {
                        role_id_file_path = "${config.sops.secrets.spindle_role_id.path}"
                        secret_id_file_path = "${config.sops.secrets.spindle_secret_id.path}"
                        remove_secret_id_file_after_reading = false
                      }
                    }
                    sink {
                      type = "file"
                      config = { path = "/var/lib/openbao-proxy/token" }
                    }
                  }
                  api_proxy {
                    use_auto_auth_token = true
                    enforce_consistency = "always"
                  }
                  listener "tcp" {
                    address = "127.0.0.1:8202"
                    tls_disable = true
                  }
                  cache { use_auto_auth_token = true }
                ''}";
                Restart = "always";
                RestartSec = "5s";
                User = "openbao-proxy";
                Group = "openbao-proxy";
              };
            };
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
              current_key = "file:///etc/openbao/unseal-key";
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
                identity.request = [
                  {
                    mount-userpass = {
                      operation = "update";
                      path = "sys/auth/userpass";
                      data = {
                        type = "userpass";
                        path = "userpass/";
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
            ];
          };
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "openbao";
          port = 8200;
          extraServiceConfig.loadBalancer.servers = [ { url = "http://100.117.131.57:8200"; } ];
        };

        users = {
          users.openbao-proxy = {
            isSystemUser = true;
            group = "openbao-proxy";
          };
          groups.openbao-proxy = { };
        };

      };
  };
}
