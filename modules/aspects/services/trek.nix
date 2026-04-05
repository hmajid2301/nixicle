{ den, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
  dataDir = "/var/lib/trek";
  port = 3000;
  domain = "trek.haseebmajid.dev";
in
{
  den.aspects.trek = {
    nixos = { config, lib, ... }: {
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          dockerSocket.enable = false;
          dockerCompat = false;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0755 root root - -"
        "d ${dataDir}/data 0755 root root - -"
        "d ${dataDir}/uploads 0755 root root - -"
        "d ${dataDir}/uploads/files 0755 root root - -"
        "d ${dataDir}/uploads/covers 0755 root root - -"
        "d ${dataDir}/uploads/avatars 0755 root root - -"
        "d ${dataDir}/uploads/photos 0755 root root - -"
      ];

      virtualisation.oci-containers.containers.trek = {
        image = "ghcr.io/mauriceboe/trek:latest";
        autoStart = true;
        ports = [ "127.0.0.1:${toString port}:3000" ];
        volumes = [
          "${dataDir}/data:/app/data"
          "${dataDir}/uploads:/app/uploads"
        ];
        environment = {
          NODE_ENV = "production";
          TZ = "UTC";
        };
      };

      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "trek";
        port = port;
      };

      services.cloudflared.tunnels.${tunnelId}.ingress.${domain} = "http://localhost:${toString port}";
    };
  };
}
