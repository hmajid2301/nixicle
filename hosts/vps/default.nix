{ den, ... }:
{
  den.aspects.vps = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.server-admin
      den.aspects.server-console
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
      den.aspects.sure
      den.aspects.homepage
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
      let
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKuM4bCeJq0XQ1vd/iNK650Bu3wPVKQTSB0k2gsMKhdE hello@haseebmajid.dev"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINP5gqbEEj+pykK58djSI1vtMtFiaYcygqhHd3mzPbSt hello@haseebmajid.dev"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwAamg3cSHP+91grc7qmrwNoPpbxD/IMi8MhqpptuM2 hello@haseebmajid.dev"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBZsm7CzZ50x8eaUrXaMmNRE2J9qK9E9X9vFHuv04E1V hello@haseebmajid.dev"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDuNpCUillp0oM7vFWpEf+EARQusfdOH2Sy1RlSDdDxr hello@haseebmajid.dev"
        ];
      in
      {
        imports = [
          ./hardware-configuration.nix
          ./disks.nix
        ];

        sops.defaultSopsFile = ./secrets.yaml;
        sops.secrets = {
          gitlab_runner_env = { };
          nixos_hashed_password.neededForUsers = true;
        };

        nixicle = {
          serverAdmin = {
            enable = true;
            inherit authorizedKeys;
            mediaGid = 3000;
            hashedPasswordFile = config.sops.secrets.nixos_hashed_password.path;
            shell = pkgs.fish;
          };

          crowdsec.allowlist = [ "82.165.193.60" ];
          serverConsole.enable = true;
        };

        security.sudo.wheelNeedsPassword = lib.mkForce false;

        networking = {
          hostName = "vps";
          useDHCP = lib.mkDefault true;
          interfaces.ens3.useDHCP = lib.mkDefault true;
          firewall.allowedTCPPorts = [ 22 ];
        };

        services.dbus.implementation = "dbus";
        services.openssh = {
          enable = true;
          ports = [ 22 ];
          settings.PasswordAuthentication = lib.mkForce false;
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
          sqlite-interactive
        ];

        system = {
          backup.objects.observability = {
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
          backup.objects.networking = {
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
          stateVersion = "24.05";
        };
      };
  };
}
