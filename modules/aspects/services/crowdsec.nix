{ ... }:
{
  den.aspects.crowdsec = {
    nixos =
      { config, lib, ... }:
      {
        sops.secrets.crowdsec_enroll_key = { };
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
        systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
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

        services.crowdsec = {
          enable = true;
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
