{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.trek;
in
{
  options.services.nixicle.trek = with types; {
    enable = mkBoolOpt false "Enable TREK collaborative trip planning";
    domain = mkOpt str "trek.haseebmajid.dev" "Domain for TREK";
    port = mkOpt int 3000 "Port for TREK";
    dataDir = mkOpt str "/var/lib/trek" "Directory to store TREK data";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          dockerSocket.enable = false;
          dockerCompat = false;
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.dataDir} 0755 root root - -"
        "d ${cfg.dataDir}/data 0755 root root - -"
        "d ${cfg.dataDir}/uploads 0755 root root - -"
        "d ${cfg.dataDir}/uploads/files 0755 root root - -"
        "d ${cfg.dataDir}/uploads/covers 0755 root root - -"
        "d ${cfg.dataDir}/uploads/avatars 0755 root root - -"
        "d ${cfg.dataDir}/uploads/photos 0755 root root - -"
      ];

      virtualisation.oci-containers.containers.trek = {
        image = "ghcr.io/mauriceboe/trek:latest";
        autoStart = true;
        ports = [ "127.0.0.1:${toString cfg.port}:3000" ];
        volumes = [
          "${cfg.dataDir}/data:/app/data"
          "${cfg.dataDir}/uploads:/app/uploads"
        ];
        environment = {
          NODE_ENV = "production";
          TZ = "UTC";
        };
      };
    }

    (mkIf config.services.traefik.enable {
      services.traefik.dynamicConfigOptions.http = lib.nixicle.mkAuthenticatedTraefikService {
        name = "trek";
        port = cfg.port;
      };
    })
    {
      services.cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          ${cfg.domain} = "http://localhost:${toString cfg.port}";
        };
      };
    }
  ]);
}
