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

  boot.loader.systemd-boot.enable = lib.mkForce false;

  system.boot.enable = lib.mkForce false;

  # VPS doesn't use impermanence, so use standard SSH key path for SOPS
  sops.age.sshKeyPaths = lib.mkForce [ "/etc/ssh/ssh_host_ed25519_key" ];

  roles.common.enable = true;

  user.name = "nixos";

  users.users.nixos = {
    initialPassword = "changeme";
  };

  time.timeZone = lib.mkForce "UTC";

  security.sudo = {
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  services.nixicle = {
    traefik.enable = true;
    tailscale.enable = true;
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
        frameDeny = true;
        contentTypeNosniff = true;
        customFrameOptionsValue = "DENY";
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
    };

    routers = {
      jellyfin = {
        entryPoints = [ "websecure" ];
        rule = "Host(`jelly.haseebmajid.dev`)";
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
        tls.certResolver = "letsencrypt";
      };
    };
  };

  networking.hostName = "vps";
  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.ens3.useDHCP = lib.mkDefault true;

  system.stateVersion = "24.05";
}
