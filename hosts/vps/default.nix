{ den, ... }:
{
  den.aspects.vps = {
    includes = [
      den.aspects.performance-base
      den.aspects.server
      den.aspects.impermanence
      den.aspects.boot
      den.aspects.hardening-vps
      den.aspects.backup-restic

      den.aspects.tailscale
      den.aspects.traefik
      den.aspects.postgresql
      den.aspects.valkey
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
      den.aspects.invidious
      den.aspects.redlib
      den.aspects.otel-collector
      den.aspects.monitoring

      den.aspects.fish
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
        ];
      in
      {
        imports = [
          ./hardware-configuration.nix
          ./disks.nix
        ];

        # TODO: Remove when nixpkgs#539168 is closed / karakeep no longer pins pnpm_9.
        # https://github.com/NixOS/nixpkgs/issues/539168
        nixpkgs.config.permittedInsecurePackages = [
          "pnpm-9.15.9"
        ];

        environment.systemPackages = with pkgs; [
          jq
          sqlite-interactive
        ];

        services.dbus.implementation = "dbus";
        services.getty.autologinUser = "nixos";

        users.mutableUsers = false;

        sops.defaultSopsFile = ./secrets.yaml;

        sops.secrets = {
          gitlab_runner_env = { };
          nixos_hashed_password = {
            neededForUsers = true;
          };
        };

        users.users.root.openssh.authorizedKeys.keys = authorizedKeys;

        users.users.nixos = {
          isNormalUser = true;
          group = "users";
          extraGroups = [ "wheel" ];
          hashedPasswordFile = config.sops.secrets.nixos_hashed_password.path;
          openssh.authorizedKeys.keys = authorizedKeys;
          shell = pkgs.fish;
        };

        time.timeZone = lib.mkForce "UTC";

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

        security.sudo.wheelNeedsPassword = lib.mkForce false;

        system.backup.objects.observability = {
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

        services.traefik.dynamicConfigOptions.http = lib.mkMerge [
          (lib.nixicle.mkTraefikService {
            name = "invidious";
            port = 3939;
            domain = "haseebmajid.dev";
            middlewares = [ "tinyauth" ];
          })
          (lib.nixicle.mkTraefikService {
            name = "redlib";
            port = 8929;
            domain = "haseebmajid.dev";
            middlewares = [ "tinyauth" ];
          })
        ];

        services.openssh = {
          enable = true;
          ports = [ 22 ];
          settings.PasswordAuthentication = lib.mkForce false;
        };

        networking = {
          firewall.allowedTCPPorts = [ 22 ];
          hostName = "vps";
          useDHCP = lib.mkDefault true;
          interfaces.ens3.useDHCP = lib.mkDefault true;
        };

        system.stateVersion = "24.05";
      };
  };
}
