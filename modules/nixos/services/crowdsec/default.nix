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
    services.crowdsec = {
      enable = true;
      settings.general.api.server = {
        listen_uri = "127.0.0.1:6060";
      };
      localConfig.acquisitions = [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
          labels.type = "syslog";
        }
      ];
    };

    # Install firewall bouncer
    systemd.services.crowdsec-firewall-bouncer = {
      description = "CrowdSec Firewall Bouncer";
      after = [ "crowdsec.service" ];
      wants = [ "crowdsec.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.crowdsec-firewall-bouncer}/bin/crowdsec-firewall-bouncer -c /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml";
        Restart = "on-failure";
      };
    };

    environment.systemPackages = with pkgs; [
      crowdsec
      crowdsec-firewall-bouncer
    ];

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
