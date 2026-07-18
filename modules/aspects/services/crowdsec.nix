{ ... }:
{
  den.aspects.crowdsec = {
    persist.directories = [
      {
        directory = "/var/lib/crowdsec";
        user = "crowdsec";
        group = "crowdsec";
        mode = "0750";
      }
    ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        yaml = pkgs.formats.yaml { };
      in
      {
        sops.secrets.crowdsec_enroll_key = { };
        sops.secrets.crowdsec_bouncer_key = { };

        # The upstream NixOS firewall-bouncer registration unit calls raw cscli,
        # which defaults to /etc/crowdsec/config.yaml instead of the NixOS-generated
        # config path. Provide that conventional path so auto-registration works.
        environment.etc."crowdsec/config.yaml".source =
          yaml.generate "crowdsec.yaml" config.services.crowdsec.settings.general;
        systemd.services.crowdsec.serviceConfig = {
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectHome = true;
          ProtectKernelLogs = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          ProtectKernelModules = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
        };
        systemd.services.crowdsec-firewall-bouncer.serviceConfig = {
          DynamicUser = lib.mkForce false;
          NoNewPrivileges = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectHome = true;
          ProtectKernelLogs = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          ProtectKernelModules = true;
          RestrictSUIDSGID = true;
          LockPersonality = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
        };
        systemd.services.crowdsec-register-firewall-bouncer = {
          description = "Register the CrowdSec firewall bouncer API key";
          wantedBy = [ "multi-user.target" ];
          after = [ "crowdsec.service" ];
          wants = [ "crowdsec.service" ];
          serviceConfig = {
            Type = "oneshot";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = true;
            ProtectKernelLogs = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            ProtectKernelModules = true;
            RestrictSUIDSGID = true;
            LockPersonality = true;
            RestrictNamespaces = true;
            RestrictRealtime = true;
            SystemCallArchitectures = "native";
          };
          path = [ config.services.crowdsec.package ];
          script = ''
            set -euo pipefail
            name="crowdsec-firewall-bouncer"
            key="$(cat ${config.sops.secrets.crowdsec_bouncer_key.path})"
            cscli -c /etc/crowdsec/config.yaml bouncers delete "$name" --ignore-missing >/dev/null
            cscli -c /etc/crowdsec/config.yaml bouncers add "$name" --key "$key" --output raw >/dev/null
          '';
        };

        systemd.services.crowdsec-firewall-bouncer = {
          after = [ "crowdsec-register-firewall-bouncer.service" ];
          requires = [ "crowdsec-register-firewall-bouncer.service" ];
          serviceConfig.ExecStartPre = lib.mkBefore [
            (pkgs.writeShellScript "wait-for-crowdsec-lapi" ''
              set -euo pipefail
              for i in $(seq 1 60); do
                if ${lib.getExe pkgs.curl} -fsS http://127.0.0.1:8081/health >/dev/null 2>&1; then
                  exit 0
                fi
                sleep 1
              done
              echo "CrowdSec local API not ready" >&2
              exit 1
            '')
          ];
        };

        services.crowdsec-firewall-bouncer = {
          enable = true;
          registerBouncer.enable = false;
          secrets.apiKeyPath = config.sops.secrets.crowdsec_bouncer_key.path;
        };

        services.crowdsec = {
          enable = true;
          hub.collections = [
            "crowdsecurity/linux"
            "crowdsecurity/sshd"
          ];
          settings = {
            general.api = {
              server = {
                enable = true;
                listen_uri = "127.0.0.1:8081";
              };
              client.credentials_path = "/var/lib/crowdsec/state/lapi-secrets.yaml";
            };
            lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-secrets.yaml";
            console.tokenFile = config.sops.secrets.crowdsec_enroll_key.path;
          };
          localConfig.acquisitions = [
            {
              source = "journalctl";
              journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
              labels.type = "syslog";
            }
          ];
        };
      };
  };
}
