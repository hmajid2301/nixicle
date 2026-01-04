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

    systemd.tmpfiles.rules = [
      "d /var/lib/crowdsec 0755 crowdsec crowdsec - -"
      "f /var/lib/crowdsec/online_api_credentials.yaml 0750 crowdsec crowdsec - -"
    ];

    services.crowdsec = {
      enable = true;

      settings = {
        general.api = {
          client.credentials_path = "/var/lib/crowdsec/local_api_credentials.yaml";
          server = {
            enable = true;
            listen_uri = "127.0.0.1:8081";
          };
        };

        lapi.credentialsFile = "/var/lib/crowdsec/local_api_credentials.yaml";
        capi.credentialsFile = "/var/lib/crowdsec/online_api_credentials.yaml";

        console = {
          tokenFile = config.sops.secrets.crowdsec_enroll_key.path;
          configuration = {
            share_manual_decisions = true;
            share_tainted = true;
            share_custom = true;
            console_management = false;
            share_context = true;
          };
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

    services.crowdsec-firewall-bouncer.enable = true;

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/crowdsec";
          user = "crowdsec";
          group = "crowdsec";
          mode = "0750";
        }
        {
          directory = "/etc/crowdsec";
          mode = "0755";
        }
      ];
    };
  };
}
