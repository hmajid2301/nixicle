{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.monitoring;
in
{
  config = mkIf cfg.enable {
    services.prometheus.alertmanager = {
      enable = true;
      configuration = {
        # global = {
        # The smarthost and SMTP sender used for mail notifications.
        # smtp_smarthost = "mail.thalheim.io:587";
        # smtp_from = "alertmanager@thalheim.io";
        # smtp_auth_username = "alertmanager@thalheim.io";
        # smtp_auth_password = "$SMTP_PASSWORD";
        # };

        route = {
          receiver = "all";
          group_by = [ "instance" ];
          group_wait = "30s";
          group_interval = "2m";
          repeat_interval = "24h";
        };

        receivers = [
          {
            name = "all";
            webhook_configs = [
              { url = "http://127.0.0.1:11000/alert"; }
              # { url = with config.services.gotify; "http://s100:8051"; }
            ];
          }
        ];
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          { directory = "/var/lib/private/alertmanager"; mode = "0750"; }
        ];
      };
    };
  };
}
