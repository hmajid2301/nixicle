{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.services.nixicle.openbao;
in
{
  imports = [
    ./proxy.nix
  ];

  options.services.nixicle.openbao = with types; {
    enable = mkBoolOpt false "Whether or not to enable OpenBao";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      systemd.tmpfiles.rules = [
        "d /var/log/openbao 0755 openbao openbao -"
        "d /etc/openbao 0755 root root -"
        "f /etc/openbao/unseal-key 0644 root root - wsCAnl5+faMlNFeAmorMVJao+rhkI1upJw+PAUFoAr0="
      ];

      sops.secrets.openbao_admin_password = {
        sopsFile = ../secrets.yaml;
      };

      sops.templates."openbao-env".content = ''
        OPENBAO_ADMIN_PASSWORD=${config.sops.placeholder.openbao_admin_password}
      '';

      services.openbao = {
        enable = true;
        package = pkgs.openbao;
        settings = {
          ui = true;
          api_addr = "http://127.0.0.1:8200";
          cluster_addr = "https://127.0.0.1:8201";

          seal = {
            static = {
              current_key = "file:///etc/openbao/unseal-key";
              current_key_id = "primary";
            };
          };

          listener = {
            tcp = {
              type = "tcp";
              address = "127.0.0.1:8200";
              tls_disable = true;
            };
          };

          storage = {
            file = {
              path = "/var/lib/openbao";
            };
          };

          initialize = [
            {
              identity = {
                request = [
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
              };
            }
            {
              policy = {
                request = [
                  {
                    add-admin-policy = {
                      operation = "update";
                      path = "sys/policies/acl/admin";
                      data = {
                        policy = ''
                          path "*" {
                            capabilities = ["create", "update", "read", "delete", "list", "scan", "sudo"]
                          }
                        '';
                      };
                    };
                  }
                ];
              };
            }
          ];
        };
      };

      systemd.services.openbao.serviceConfig = {
        EnvironmentFile = config.sops.templates."openbao-env".path;
      };
    }
    {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "openbao";
        port = 8200;
        extraServiceConfig = {
          loadBalancer.servers = [ { url = "http://100.117.131.57:8200"; } ];
        };
      };
    }
    {
      environment.persistence."/persist" = mkIf config.system.impermanence.enable {
        directories = [
          "/var/lib/private/openbao"
          "/var/log/openbao"
        ];
      };
    }
  ]);
}
