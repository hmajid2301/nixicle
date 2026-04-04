{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;

let
  cfg = config.services.nixicle.openbao.proxy;
in
{
  options.services.nixicle.openbao.proxy = with types; {
    enable = mkBoolOpt false "Enable OpenBao proxy with AppRole auto-auth";
  };

  config = mkIf cfg.enable {
    sops.secrets.spindle_role_id = {
      sopsFile = ../secrets.yaml;
      owner = "openbao-proxy";
    };

    sops.secrets.spindle_secret_id = {
      sopsFile = ../secrets.yaml;
      owner = "openbao-proxy";
    };

    users.users.openbao-proxy = {
      isSystemUser = true;
      group = "openbao-proxy";
      description = "OpenBao proxy user";
    };

    users.groups.openbao-proxy = { };

    systemd.services.openbao-proxy = {
      description = "OpenBao Proxy with Auto-Auth";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "openbao.service" ];

      preStart = ''
        mkdir -p /var/lib/openbao-proxy
        mkdir -p /etc/openbao
        chown openbao-proxy:openbao-proxy /var/lib/openbao-proxy
      '';

      serviceConfig = {
        ExecStart = "${pkgs.openbao}/bin/bao proxy -config=${
          pkgs.writeText "openbao-proxy.hcl" ''
            vault {
              address = "http://127.0.0.1:8200"
              retry {
                num_retries = 5
              }
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
                config = {
                  path = "/var/lib/openbao-proxy/token"
                }
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

            cache {
              use_auto_auth_token = true
            }
          ''
        }";
        Restart = "always";
        RestartSec = "5s";
        User = "openbao-proxy";
        Group = "openbao-proxy";
      };
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/openbao-proxy";
          user = "openbao-proxy";
          group = "openbao-proxy";
          mode = "0750";
        }
        "/etc/openbao"
      ];
    };
  };
}
