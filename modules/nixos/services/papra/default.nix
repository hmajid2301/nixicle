{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.papra;
in
{
  options.services.nixicle.papra = with types; {
    enable = mkBoolOpt false "Enable the Papra document management service";
    domain = mkOpt str "papra.haseebmajid.dev" "Domain for Papra";
    port = mkOpt int 1221 "Port for Papra web interface";
    dataDir = mkOpt str "/var/lib/papra" "Directory to store Papra data";
    baseUrl = mkOpt str "https://${cfg.domain}" "Base URL for Papra";

    encryption = {
      enable = mkBoolOpt true "Enable document encryption";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        dockerSocket.enable = false;
        dockerCompat = false;
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 999 999 -"
      "d ${cfg.dataDir}/app-data 0750 999 999 -"
      "d ${cfg.dataDir}/app-data/db 0750 999 999 -"
      "d ${cfg.dataDir}/app-data/documents 0750 999 999 -"
    ];

    sops.secrets.papra-env = mkIf cfg.enable {
      sopsFile = ../secrets.yaml;
    };

    virtualisation.oci-containers.containers.papra = {
      image = "ghcr.io/papra-hq/papra:latest-rootless";
      autoStart = true;
      ports = [ "127.0.0.1:${toString cfg.port}:1221" ];
      volumes = [
        "${cfg.dataDir}/app-data:/app/app-data"
      ];
      environment = {
        APP_BASE_URL = cfg.baseUrl;
        NODE_ENV = "production";
      }
      // lib.optionalAttrs cfg.encryption.enable {
        DOCUMENT_STORAGE_ENCRYPTION_IS_ENABLED = "true";
      };
      environmentFiles = [
        config.sops.secrets.papra-env.path
      ];
    };

    systemd.services.podman-papra = {
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          {
            directory = cfg.dataDir;
            user = "999";
            group = "999";
            mode = "0750";
          }
        ];
      };
    };

    services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
      ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
        ${cfg.domain} = "http://localhost:${toString cfg.port}";
      };
    };
  };
}
