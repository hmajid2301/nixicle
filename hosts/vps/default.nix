{ den, ... }:
{
  den.aspects.vps = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.tailscale
      den.aspects.traefik
      den.aspects.uptime-kuma
    ];

    nixos =
      { lib, ... }:
      {
        imports = [
          ./hardware-configuration.nix
          ./disks.nix
        ];

        boot = {
          loader.systemd-boot.enable = lib.mkForce false;
          loader.grub.enable = lib.mkDefault true;
          initrd.systemd.enable = lib.mkForce false;
        };

        services.dbus.implementation = "dbus";

        sops.age.sshKeyPaths = lib.mkForce [ "/etc/ssh/ssh_host_ed25519_key" ];

        users.users.nixos = {
          isNormalUser = true;
          group = "users";
          extraGroups = [ "wheel" ];
          initialPassword = "changeme";
        };

        time.timeZone = lib.mkForce "UTC";

        security.sudo = {
          wheelNeedsPassword = false;
          execWheelOnly = true;
        };

        services.traefik.dynamicConfigOptions.http = {
          services = {
            jellyfin.loadBalancer = {
              servers = [ { url = "http://framebox:8096"; } ];
              passHostHeader = true;
            };
            immich.loadBalancer = {
              servers = [ { url = "http://framebox:2283"; } ];
              passHostHeader = true;
            };
            attic.loadBalancer = {
              servers = [ { url = "http://framebox:8899"; } ];
              passHostHeader = true;
              responseForwarding.flushInterval = "100ms";
              serversTransport = "attic-transport";
            };
          };

          middlewares = {
            jellyfin-headers.headers = {
              customResponseHeaders.X-Robots-Tag = "noindex, nofollow, nosnippet, noarchive";
              customRequestHeaders.X-Forwarded-Proto = "https";
              sslRedirect = true;
              sslForceHost = true;
              stsSeconds = 315360000;
              stsIncludeSubdomains = true;
              stsPreload = true;
              frameDeny = false;
              contentTypeNosniff = true;
              customFrameOptionsValue = "SAMEORIGIN";
            };
            immich-headers.headers = {
              customResponseHeaders.X-Robots-Tag = "noindex, nofollow, nosnippet, noarchive";
              customRequestHeaders.X-Forwarded-Proto = "https";
              sslRedirect = true;
              sslForceHost = true;
              stsSeconds = 315360000;
              stsIncludeSubdomains = true;
              stsPreload = true;
              contentTypeNosniff = true;
            };
            attic-timeout.buffering = {
              maxRequestBodyBytes = 21474836480;
              memRequestBodyBytes = 1073741824;
            };
          };

          serversTransports.attic-transport.forwardingTimeouts = {
            dialTimeout = "30s";
            responseHeaderTimeout = "10m";
            idleConnTimeout = "10m";
          };

          routers = {
            jellyfin = {
              entryPoints = [ "websecure" ];
              rule = "Host(`jellyfin.haseebmajid.dev`)";
              service = "jellyfin";
              middlewares = [ "jellyfin-headers" ];
              tls.certResolver = "letsencrypt";
            };
            immich = {
              entryPoints = [ "websecure" ];
              rule = "Host(`immich.haseebmajid.dev`)";
              service = "immich";
              middlewares = [ "immich-headers" ];
              tls.certResolver = "letsencrypt";
            };
            attic = {
              entryPoints = [ "websecure" ];
              rule = "Host(`attic.haseebmajid.dev`)";
              service = "attic";
              middlewares = [ "attic-timeout" ];
              tls.certResolver = "letsencrypt";
            };
          };
        };

        networking = {
          hostName = "vps";
          useDHCP = lib.mkDefault true;
          interfaces.ens3.useDHCP = lib.mkDefault true;
        };

        system.stateVersion = "24.05";
      };
  };
}
