{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  boot.loader.grub.enable = true;
  system.boot.enable = lib.mkForce false;

  roles.kubernetes = {
    enable = true;
    role = "server";
  };

  sops.secrets.cloudflared_vps = {
    sopsFile = ../../../modules/nixos/services/secrets.yaml;
  };

  sops.secrets.gitlab_runner_env_vps = {
    sopsFile = ../../../modules/nixos/services/secrets.yaml;
  };

  # TODO: Import modern unix?
  # environment.systemPackages = with pkgs; [
  #   opencode
  #   claude-code
  # ];

  services = {
    avahi.enable = lib.mkForce false;

    cloudflared = {
      enable = true;
      tunnels = {
        "0e845de6-544a-47f2-a1d5-c76be02ce153" = {
          credentialsFile = config.sops.secrets.cloudflared_vps.path;
          default = "http_status:404";
        };
      };
    };

    nixicle = {
      alloy.enable = true;
      otel-collector.enable = true;
      traefik.enable = true;
      logging.enable = true;
      postgresql.enable = true;
      plausible.enable = true;
      n8n.enable = true;
      gotify.enable = true;
      uptime-kuma.enable = true;
      openbao.enable = true;

      gitlab-runner = {
        enable = true;
        sopsFile = config.sops.secrets.gitlab_runner_env_vps.path;
      };
    };

    traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            jellyfin.loadBalancer.servers = [ { url = "http://ms01:8096"; } ];
            immich.loadBalancer.servers = [ { url = "http://ms01:2283"; } ];
          };

          routers = {
            jellyfin = {
              entryPoints = [ "websecure" ];
              rule = "Host(`jellyfin.haseebmajid.dev`)";
              service = "jellyfin";
              tls.certResolver = "letsencrypt";
            };
            immich = {
              entryPoints = [ "websecure" ];
              rule = "Host(`immich.haseebmajid.dev`)";
              service = "immich";
              tls.certResolver = "letsencrypt";
            };
          };
        };
      };
    };
  };

  system.stateVersion = "24.05";
}
