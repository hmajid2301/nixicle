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
  options.services.nixicle.openbao = with types; {
    enable = mkBoolOpt false "Whether or not to enable OpenBao";
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/log/openbao 0755 openbao openbao -"
    ];

    # TODO: SOPS secret for admin password (for future self-init)
    # sops.secrets.openbao_admin_password = {
    #   sopsFile = ../secrets.yaml;
    # };

    services.openbao = {
      enable = true;
      package = pkgs.openbao;
      settings = {
        ui = true;
        api_addr = "http://0.0.0.0:8200";
        cluster_addr = "https://0.0.0.0:8201";

        listener = {
          tcp = {
            type = "tcp";
            address = "0.0.0.0:8200";
            tls_disable = true;
          };
        };

        storage = {
          file = {
            path = "/var/lib/openbao";
          };
        };

        # TODO: Enable declarative self-initialization once available
        # See: https://openbao.org/docs/rfcs/self-init/
        # initialize = [
        #   {
        #     audit = {
        #       request = [
        #         {
        #           enable-audit = {
        #             operation = "update";
        #             path = "sys/audit/file";
        #             data = {
        #               type = "file";
        #               options = {
        #                 file_path = "/var/log/openbao/audit.log";
        #                 log_raw = false;
        #               };
        #             };
        #           };
        #         }
        #       ];
        #     };
        #   }
        #   {
        #     identity = {
        #       request = [
        #         {
        #           mount-userpass = {
        #             operation = "update";
        #             path = "sys/auth/userpass";
        #             data = {
        #               type = "userpass";
        #               path = "userpass/";
        #               description = "Local userpass authentication";
        #             };
        #           };
        #         }
        #         {
        #           userpass-add-admin = {
        #             operation = "update";
        #             path = "auth/userpass/users/admin";
        #             data = {
        #               password = {
        #                 eval_type = "string";
        #                 eval_source = "env";
        #                 env_var = "OPENBAO_ADMIN_PASSWORD";
        #               };
        #               token_policies = ["admin"];
        #             };
        #           };
        #         }
        #       ];
        #     };
        #   }
        #   {
        #     policy = {
        #       request = [
        #         {
        #           add-admin-policy = {
        #             operation = "update";
        #             path = "sys/policies/acl/admin";
        #             data = {
        #               policy = ''
        #                 path "*" {
        #                   capabilities = ["create", "update", "read", "delete", "list", "scan", "sudo"]
        #                 }
        #               '';
        #             };
        #           };
        #         }
        #       ];
        #     };
        #   }
        # ];
      };
    };

    # TODO: Configure environment variable for admin password (for future self-init)
    # systemd.services.openbao.serviceConfig.EnvironmentFile = config.sops.secrets.openbao_admin_password.path;

    services.traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            openbao.loadBalancer.servers = [
              {
                url = "http://localhost:8200";
              }
            ];
          };

          routers = {
            openbao = {
              entryPoints = [ "websecure" ];
              rule = "Host(`openbao.homelab.haseebmajid.dev`)";
              service = "openbao";
              tls.certResolver = "letsencrypt";
            };
          };
        };
      };
    };
  };
}
