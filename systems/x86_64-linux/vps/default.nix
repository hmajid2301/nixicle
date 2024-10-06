{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  boot.loader.grub.enable = true;

  roles.server.enable = true;
  system.boot.enable = lib.mkForce false;

  services = {
    nixicle.avahi.enable = lib.mkForce false;
    nixicle.traefik.enable = true;

    traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            jellyfin.loadBalancer.servers = [
              {
                url = "http://ms01:8096";
              }
            ];
            immich.loadBalancer.servers = [
              {
                url = "http://ms01:3001";
              }
            ];
          };

          routers = {
            jellyfin = {
              entryPoints = ["websecure"];
              rule = "Host(`jellyfin.haseebmajid.dev`)";
              service = "jellyfin";
              tls.certResolver = "letsencrypt";
            };
            immich = {
              entryPoints = ["websecure"];
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
