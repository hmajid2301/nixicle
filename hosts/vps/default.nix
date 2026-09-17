{ den, ... }:
{
  den.aspects.vps = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.server-admin
      den.aspects.impermanence
      den.aspects.boot
      den.aspects.hardening-vps
      den.aspects.backup-restic
      den.aspects.attic-cache

      den.aspects.tailscale
      den.aspects.traefik
      den.aspects.nfs-nas
      den.aspects.postgresql
      den.aspects.redis
      den.aspects.attic-server
      den.aspects.crowdsec
      den.aspects.openbao
      den.aspects.pocketid
      den.aspects.garage
      den.aspects.tangled
      den.aspects.gitlab-runner

      den.aspects.atuin
      den.aspects.banterbus
      den.aspects.goroutinely
      den.aspects.lettucego
      den.aspects.karakeep
      den.aspects.papra
      den.aspects.tandoor
      den.aspects.tinyauth
      den.aspects.otel-collector
      den.aspects.ollama
      den.aspects.monitoring
      den.aspects.monitoringAlerts
      den.aspects.gotify
      den.aspects.sure
      den.aspects.homepage
      den.aspects.hister
      den.aspects.immich

      den.aspects.fish
      (den.batteries.tty-autologin "nixos")
    ];

    nixos =
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

        sops.defaultSopsFile = ./secrets.yaml;
        sops.secrets = {
          gitlab_runner_env = { };
          gitlab_runner_docker_env = { };
          nixos_hashed_password.neededForUsers = true;
        };

        nixicle = {
          serverAdmin = {
            enable = true;
            mediaGid = 3000;
            hashedPasswordFile = config.sops.secrets.nixos_hashed_password.path;
            shell = pkgs.fish;
          };

          crowdsec = {
            allowlist = [
              "82.165.193.60"
              "146.70.189.96"
            ];
            allowlistUris = [ "/api/add" ];
          };
        };

        security.sudo.wheelNeedsPassword = lib.mkForce false;

        users.users.herdr = {
          extraGroups = [ ];
          hashedPassword = "!";
          linger = true;
        };

        systemd.tmpfiles.rules = [
          "d /home/herdr 0700 herdr users -"
          "d /home/herdr/projects 0700 herdr users -"
        ];

        assertions = [
          {
            assertion = builtins.all (group: !builtins.elem group config.users.users.herdr.extraGroups) [
              "wheel"
              "networkmanager"
            ];
            message = "The herdr user must not belong to privileged groups";
          }
        ];

        networking = {
          hostName = "vps";
          useDHCP = lib.mkDefault true;
          interfaces.ens3.useDHCP = lib.mkDefault true;
          firewall.allowedTCPPorts = [ 22 ];
          # Mosh UDP 60000-61000 is reachable through trusted tailscale0 only.
          # Public firewall intentionally exposes no UDP ports.
        };

        services = {
          dbus.implementation = "dbus";
          openssh = {
            enable = true;
            ports = [ 22 ];
            settings.PasswordAuthentication = lib.mkForce false;
          };
          tailscale.extraSetFlags = [ "--ssh" ];
          traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
            name = "jellyfin";
            port = 8096;
            subdomain = "jellyfin";
            domain = "haseebmajid.dev";
            extraServiceConfig = {
              loadBalancer.servers = lib.mkForce [ { url = "http://nas:8096"; } ];
            };
          };
        };

        nix.settings = {
          trusted-users = [
            "root"
            "@wheel"
          ];
          experimental-features = [
            "nix-command"
            "flakes"
          ];
        };

        time.timeZone = lib.mkForce "UTC";

        environment.systemPackages = with pkgs; [
          jq
          mosh
          sqlite-interactive
        ];

        system = {
          backup.objects = {
            observability = {
              paths = [
                "/var/lib/prometheus2"
                "/var/lib/loki"
                "/var/lib/grafana"
              ];
              timerConfig = {
                OnCalendar = "daily";
                RandomizedDelaySec = "2h";
                Persistent = true;
              };
            };
            networking = {
              paths = [
                "/var/lib/traefik"
                "/var/lib/tailscale"
              ];
              timerConfig = {
                OnCalendar = "daily";
                RandomizedDelaySec = "3h";
                Persistent = true;
              };
            };
            herdr = {
              paths = [ "/home/herdr" ];
              exclude = [
                "/home/herdr/.cache"
                "/home/herdr/.local/share/Trash"
                "**/.direnv"
                "**/node_modules"
                "**/target"
              ];
              timerConfig = {
                OnCalendar = "daily";
                RandomizedDelaySec = "4h";
                Persistent = true;
              };
            };
          };
          stateVersion = "24.05";
        };
      };
  };
}
