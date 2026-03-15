{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.goroutinely;
in
{
  options.services.nixicle.goroutinely = {
    enable = mkEnableOption "Enable the goroutinely service";
  };

  config = mkIf cfg.enable {
    sops.secrets.goroutinely = {
      sopsFile = ../secrets.yaml;
      key = "goroutinely";
      owner = config.services.goroutinely.user;
      group = config.services.goroutinely.group;
      mode = "0400";
    };

    services = {
      goroutinely = {
        enable = true;
        package = inputs.goroutinely.packages.${pkgs.system}.default;
        sendremindersPackage = inputs.goroutinely.packages.${pkgs.system}.default;
        port = 8235;
        host = "0.0.0.0";
        database.createLocally = true;
        notifications = {
          enable = true;
          vapidSubject = "mailto:admin@haseebmajid.dev";
          vapidPublicKey = "BN91igKCVVyiiDggAN4poSUaEKL_-CNV_3mnioXKghZd00x5fFkjLra8HvAhfwZkHTymFsXHsRwVYpTqyGja-II";
        };
        oauth = {
          issuerUrl = "https://authentik.haseebmajid.dev/application/o/go-routinely/.well-known/openid-configuration";
          clientId = "N3h5Y0H52Z96NqKfJn8fWasyPX5VRdtx5ps0uoWW";
        };
        secretsFile = config.sops.secrets.goroutinely.path;
      };

      cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "goroutinely.haseebmajid.dev" = "http://localhost:8235";
        };
      };

      traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
        name = "goroutinely";
        port = 8235;
        subdomain = "goroutinely";
        domain = "haseebmajid.dev";
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          {
            directory = "/var/lib/goroutinely";
            user = "goroutinely";
            group = "goroutinely";
            mode = "0750";
          }
        ];
      };
    };
  };
}
