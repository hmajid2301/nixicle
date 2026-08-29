_:
let
  dataDir = "/var/lib/trek";
  port = 3000;
in
{
  den.aspects.trek = {
    nixos =
      { lib, ... }:
      {
        virtualisation.oci-containers.backend = "docker";

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
          inherit port;
        };

      };
  };
}
