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
      settings.api.server.listen_uri = "127.0.0.1:6060";
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
