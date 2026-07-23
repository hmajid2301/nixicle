{
  inputs,
  den,
  ...
}:
{
  flake-file.inputs.nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

  den.aspects.rpi = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.fish
      den.aspects.hardening-vps
      den.aspects.backup-restic
      den.aspects.tailscale
      den.aspects.traefik
      den.aspects.nixflix
      den.aspects.adguard
      den.aspects.navidrome
      den.aspects.homepage
      den.aspects.docker
      den.aspects.romm
    ];

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwAamg3cSHP+91grc7qmrwNoPpbxD/IMi8MhqpptuM2 hello@haseebmajid.dev"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZsm7CzZ50x8eaUrXaMmNRE2J9qK9E9X9vFHuv04E1V hello@haseebmajid.dev"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICLrECFz5PQ5D2+QXomsLK9HcZhHzcBUIDGkiI94c6Ux hello@haseebmajid.dev"
        ];
      in
      {
        imports = [
          ./hardware.nix
          ./disks.nix
        ];

        networking = {
          hostName = "rpi";
          useDHCP = lib.mkDefault true;
        };

        sops.defaultSopsFile = ./secrets.yaml;
        sops.age.sshKeyPaths = lib.mkForce [ "/etc/ssh/ssh_host_ed25519_key" ];

        nix.settings = {
          extra-substituters = [ "https://nixos-raspberrypi.cachix.org" ];
          extra-trusted-public-keys = [
            "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
          ];
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [
            "root"
            "@wheel"
          ];
        };

        users.mutableUsers = false;
        users.groups.media.gid = 3000;

        users.users.root.openssh.authorizedKeys.keys = authorizedKeys;
        users.users.nixos = {
          isNormalUser = true;
          group = "users";
          extraGroups = [
            "wheel"
            "media"
          ];
          initialPassword = "changeme";
          openssh.authorizedKeys.keys = authorizedKeys;
          shell = pkgs.fish;
        };

        services.getty.autologinUser = "nixos";

        services.openssh = {
          enable = true;
          ports = [ 22 ];
        };

        time.timeZone = "UTC";

        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
        nix.optimise.automatic = true;

        services.resolved.settings.Resolve.DNSStubListener = false;

        system.backup.objects.data = {
          paths = [ "/data" ];
          exclude = [
            "/data/downloads"
            "/data/media"
            "/data/romm/db"
          ];
          timerConfig = {
            OnCalendar = "daily";
            RandomizedDelaySec = "2h";
            Persistent = true;
          };
        };

        systemd.tmpfiles.rules = [
          "d /data 0755 root media - -"
          "d /data/media 0775 root media - -"
          "d /data/media/Music 0775 root media - -"
          "d /data/.state 0775 root media - -"
          "d /data/downloads 0775 root media - -"
        ];

        nixflix = {
          mediaDir = lib.mkForce "/data/media";
          stateDir = lib.mkForce "/data/.state";

          jellyfin.encoding = lib.mkForce {
            hardwareAccelerationType = "v4l2m2m";
            enableHardwareEncoding = false;
          };
        };

        services.navidrome.settings.MusicFolder = lib.mkForce "/data/media/Music";

        services.adguardhome.settings.dhcp = {
          enabled = false;
          interface_name = "end0";
          dhcpv4 = {
            gateway_ip = "10.0.0.1";
            subnet_mask = "255.255.255.0";
            range_start = "10.0.0.100";
            range_end = "10.0.0.200";
            lease_duration = 86400;
          };
        };
        networking.firewall.allowedUDPPorts = [ 67 ];

        services.traefik.staticConfigOptions.entryPoints.websecure.http.tls.certResolver =
          lib.mkForce "tailscale";

        networking.firewall.allowedTCPPorts = [ 22 ];

        virtualisation.docker.storageDriver = lib.mkForce "overlay2";
        virtualisation.docker.rootless.enable = lib.mkForce false;

        system.stateVersion = "26.05";
      };
  };
}
