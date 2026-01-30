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

    # Fix credential loading issue: bouncer needs to run as crowdsec user to access
    # the API key file created by the registration service
    systemd.services.crowdsec-firewall-bouncer.serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "crowdsec";
      Group = "crowdsec";
    };

    # Allow DynamicUser for the register service - it will create its own state directory
    # On impermanence systems, the directory will be recreated and bouncer re-registered
    systemd.services.crowdsec-firewall-bouncer-register.serviceConfig = {
      # Ensure the ExecStartPre checks if we need to delete the old bouncer
      ExecStartPre = lib.mkBefore [
        ''${pkgs.bash}/bin/bash -c "if ${pkgs.coreutils}/bin/test ! -f /var/lib/crowdsec-firewall-bouncer-register/api-key.cred; then /run/current-system/sw/bin/cscli bouncers delete crowdsec-firewall-bouncer || true; fi"''
      ];
    };

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
        # Don't persist crowdsec-firewall-bouncer-register - let DynamicUser recreate it
        # The bouncer will be re-registered on each boot via the register service
      ];
    };
  };
}
