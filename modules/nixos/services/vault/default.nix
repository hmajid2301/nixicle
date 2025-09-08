{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.vault;
in
{
  options.services.nixicle.vault = with types; {
    enable = mkBoolOpt false "Whether or not to enable HashiCorp Vault";
  };

  config = mkIf cfg.enable {
    services.vault = {
      enable = true;
      address = "0.0.0.0:8200";
      storageBackend = "file";
      storagePath = "/var/lib/vault";
      extraConfig = ''
        ui = true
        api_addr = "http://0.0.0.0:8200"
        cluster_addr = "http://0.0.0.0:8201"
      '';
    };

    services.traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            vault.loadBalancer.servers = [
              {
                url = "http://localhost:8200";
              }
            ];
          };

          routers = {
            vault = {
              entryPoints = [ "websecure" ];
              rule = "Host(`vault.homelab.haseebmajid.dev`)";
              service = "vault";
              tls.certResolver = "letsencrypt";
            };
          };
        };
      };
    };
  };
}