{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
  ];

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  services = {
    tandoor.enable = true;
    media-server.enable = true;
    # vpn.enable = true;
    traefik = {
      dynamicConfigOptions = {
        http = {
          services = {
            # TODO: how to do this over devices?
            homeassistant.loadBalancer.servers = [
              {
                url = "http://192.168.1.44:8123";
              }
            ];
          };

          routers = {
            homeassistant = {
              entryPoints = ["websecure"];
              rule = "Host(`home-assistant.bare.homelab.haseebmajid.dev`)";
              service = "homeassistant";
              tls.certResolver = "letsencrypt";
            };

            traefik-dashboard = {
              entryPoints = ["websecure"];
              rule = "Host(`traefik.bare.homelab.haseebmajid.dev`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
              service = "api@internal";
              tls.certResolver = "letsencrypt";
              # middlewares = ["authentik"];
            };
          };
        };
      };
    };

    nixicle = {
      authentik.enable = true;
      cloudflared.enable = true;
      monitoring.enable = true;
      netdata.enable = true;
      gitlab-runner.enable = true;
      gotify.enable = true;
      nfs.enable = true;
      paperless.enable = true;
      photoprism.enable = true;
      postgresql.enable = true;
      syncthing.enable = true;
      traefik.enable = true;
    };
  };

  roles = {
    kubernetes = {
      enable = true;
      role = "agent";
    };
  };

  # networking.interfaces.enp1s0.wakeOnLan.enable = true;

  topology.self = {
    hardware.info = "MS01";
  };

  boot = {
    supportedFilesystems = lib.mkForce ["btrfs"];
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";

    initrd = {
      supportedFilesystems = ["nfs"];
      kernelModules = ["nfs"];
    };
  };

  system.stateVersion = "23.11";
}
