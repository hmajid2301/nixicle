{
  config,
  lib,
  inputs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.dokploy;
in
{
  options.services.nixicle.dokploy = {
    enable = mkEnableOption "Enable Dokploy self-hosted PaaS";
  };

  config = mkIf cfg.enable {
    imports = [
      inputs.nix-dokploy.nixosModules.dokploy
    ];

    services.dokploy = {
      enable = true;
      database.useHostPostgres = true;
    };

    services.postgresql = {
      ensureDatabases = [ "dokploy" ];
      ensureUsers = [{
        name = "dokploy";
        ensureDBOwnership = true;
      }];
    };

    services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
      name = "dokploy";
      port = 3000;
      subdomain = "dokploy";
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        "/etc/dokploy"
      ];
    };
  };
}
