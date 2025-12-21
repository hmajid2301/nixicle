{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.unifi;
in
{
  options.services.nixicle.unifi = {
    enable = mkEnableOption "UniFi Network Controller";
  };

  config = mkIf cfg.enable {
    services.nixicle.mongodb.enable = true;

    services.unifi = {
      enable = true;
      unifiPackage = pkgs.unifi;
      mongodbPackage = pkgs.mongodb-7_0;
      initialJavaHeapSize = 1024;
      maximumJavaHeapSize = 1024;
    };

    networking.firewall = {
      allowedTCPPorts = [
        8081
        8444
      ];
      allowedUDPPorts = [
        3478
        5514
      ];
    };

    environment.etc."unifi/system.properties" = {
      text = ''
        unifi.http.port=8081
        unifi.https.port=8444
        unifi.http.interface=0.0.0.0
        unifi.https.interface=0.0.0.0
      '';
      mode = "0644";
    };

    systemd.services.unifi.preStart = ''
      mkdir -p /var/lib/unifi/data
      cp /etc/unifi/system.properties /var/lib/unifi/data/system.properties
      chown unifi:unifi /var/lib/unifi/data/system.properties
    '';

    services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
      ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
        "unifi.haseebmajid.dev" = "http://localhost:8444";
        originRequest = {
          noTLSVerify = true;
        };
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          {
            directory = "/var/lib/unifi";
            user = "unifi";
            group = "unifi";
            mode = "0755";
          }
        ];
      };
    };
  };
}
