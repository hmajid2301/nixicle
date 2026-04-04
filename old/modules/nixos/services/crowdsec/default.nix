{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.crowdsec;
in
{
  options.services.nixicle.crowdsec = {
    enable = mkEnableOption "Enable CrowdSec intrusion prevention system";
  };

  config = mkIf cfg.enable {
    sops.secrets.crowdsec_enroll_key = {
      sopsFile = ../secrets.yaml;
    };

    systemd.services.crowdsec-firewall-bouncer.serviceConfig.DynamicUser = mkForce false;

    systemd.services.crowdsec-firewall-bouncer-register.serviceConfig.DynamicUser = mkForce false;

    services.crowdsec = {
      enable = true;

      settings = {
        general = {
          api = {
            server = {
              enable = true;
              listen_uri = "127.0.0.1:8081";
            };
            client = {
              credentials_path = "/var/lib/crowdsec/state/lapi-secrets.yaml";
            };
          };
        };

        lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-secrets.yaml";

        console = {
          tokenFile = config.sops.secrets.crowdsec_enroll_key.path;
        };
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
}
