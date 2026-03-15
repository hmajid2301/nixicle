{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.crowdsec;
  format = pkgs.formats.yaml { };
in
{
  options.services.nixicle.crowdsec = {
    enable = mkEnableOption "Enable CrowdSec intrusion prevention system";
  };

  config = mkIf cfg.enable {
    sops.secrets.crowdsec_enroll_key = {
      sopsFile = ../secrets.yaml;
    };

    services.crowdsec = {
      enable = true;

      settings = {
        general.api.server = {
          enable = true;
          listen_uri = "127.0.0.1:8081";
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

    environment.etc."crowdsec/config.yaml".source = format.generate "crowdsec.yaml" config.services.crowdsec.settings.general;

    systemd.services.crowdsec-firewall-bouncer = {
      after = [ "nftables.service" ];
      partOf = [ "nftables.service" ];
    };

    systemd.services.crowdsec-firewall-bouncer.serviceConfig.DynamicUser = mkForce false;

    systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
      DynamicUser = mkForce false;
      User = config.services.crowdsec.user;
      Group = config.services.crowdsec.group;
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [ "/var/lib/crowdsec" ];
    };
  };
}
