{ den, lib, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
  dataDir = "/var/lib/papra";
  port = 1221;
  domain = "papra.haseebmajid.dev";
in
{
  den.aspects.papra = {
    includes = [ (import ./_persist-forwarder.nix { inherit den lib; }) ];
    persist.directories = [
          { directory = dataDir; user = "999"; group = "999"; mode = "0750"; }
        ];
    nixos = { config, lib, ... }: {
      sops.secrets.papra-env.sopsFile = ../../../hosts/framebox/secrets.yaml;

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
        "d ${dataDir} 0750 999 999 -"
        "d ${dataDir}/app-data 0750 999 999 -"
        "d ${dataDir}/app-data/db 0750 999 999 -"
        "d ${dataDir}/app-data/documents 0750 999 999 -"
      ];

      virtualisation.oci-containers.containers.papra = {
        image = "ghcr.io/papra-hq/papra:latest-rootless";
        autoStart = true;
        ports = [ "127.0.0.1:${toString port}:1221" ];
        volumes = [ "${dataDir}/app-data:/app/app-data" ];
        environment = {
          APP_BASE_URL = "https://${domain}";
          NODE_ENV = "production";
          DOCUMENT_STORAGE_ENCRYPTION_IS_ENABLED = "true";
        };
        environmentFiles = [ config.sops.secrets.papra-env.path ];
      };

      systemd.services.podman-papra = {
        after = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
      };

      services.cloudflared.tunnels.${tunnelId}.ingress.${domain} = "http://localhost:${toString port}";

    };
  };
}
