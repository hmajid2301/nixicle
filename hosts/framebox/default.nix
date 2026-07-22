{
  inputs,
  den,
  lib,
  ...
}:
{
  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den = {
    aspects = {
      haseeb = {
        includes = [
          (
            { user, ... }:
            {
              nixos = {
                users.users.haseeb.openssh.authorizedKeys.keys = user.authorizedKeys;
                users.users.root.openssh.authorizedKeys.keys = user.authorizedKeys;
                home-manager.users.haseeb.programs.git = {
                  settings.user.email = lib.mkForce user.email;
                  signing.key = lib.mkForce user.signingKey;
                };
              };
            }
          )
        ];

        homeManager = _: {
          programs.git.signing = {
            format = "ssh";
            signByDefault = true;
          };
        };
      };

      haseeb.provides.framebox = {
        includes = [
          den.aspects.desktopProfile
          den.aspects.gaming
          den.aspects.social
          den.aspects.video
        ];

        homeManager =
          {
            ...
          }:
          {
            home = {
              username = "haseeb";
              homeDirectory = "/home/haseeb";
              stateVersion = "26.05";
            };

            programs.noctalia-shell.settings.idle = {
              enabled = true;
              screenOffTimeout = 330;
              lockTimeout = 300;
              suspendTimeout = 0;
              fadeDuration = 5;
            };
          };
      };

      framebox = {
        includes = [
          den.aspects.performance-balanced
          den.aspects.nfs-nas
          den.aspects.impermanence
          den.aspects.boot-secure
          den.aspects.tailscale
          den.aspects.kvm
          den.aspects.traefik
          den.aspects.cloudflare
          den.aspects.atuin
          den.aspects.atticd
          den.aspects.banterbus
          # den.aspects.btrbk
          den.aspects.crowdsec
          den.aspects.docker
          den.aspects.forgejo
          den.aspects.goroutinely
          den.aspects.garage
          den.aspects.gothreads
          den.aspects.lettucego
          den.aspects.gothreads
          den.aspects.gitlab-runner
          den.aspects.immich
          den.aspects.karakeep
          den.aspects.llama-cpp
          den.aspects.ollama
          den.aspects.otel-collector
          den.aspects.redis
          den.aspects.valkey
          den.aspects.postgresql
          den.aspects.tandoor
          den.aspects.papra
          den.aspects.bentopdf
          den.aspects.fish
          den.aspects.monitoring
          den.aspects.homepage
          den.aspects.home-assistant
          den.aspects.searx
          den.aspects.zellij
          den.aspects.nixflix
          # den.aspects.open-webui
          # den.aspects.gitea
          # den.aspects.tangled
          # den.aspects.paperless
          # den.aspects.trek
        ];

        nixos =
          {
            config,
            pkgs,
            ...
          }:
          {
            imports = [
              ./hardware-configuration.nix
              ./disks.nix
              inputs.nixos-facter-modules.nixosModules.facter
              { config.facter.reportPath = ./facter.json; }
              inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
            ];

            sops.defaultSopsFile = ./secrets.yaml;

            sops.secrets = {
              gitlab_runner_env = { };
              user_password = {
                neededForUsers = true;
              };
            };

            users = {
              users.haseeb = {
                hashedPasswordFile = config.sops.secrets.user_password.path;
                shell = pkgs.fish;
                extraGroups = [
                  "wheel"
                  "media"
                  "dialout"
                ];
              };
              groups.media.gid = 3000;
            };

            environment.persistence."/persist".directories = [
              {
                directory = "/var/lib/qBittorrent";
                user = "qbittorrent";
                group = "qbittorrent";
                mode = "0755";
              }
              {
                directory = "/data/.state";
                user = "root";
                group = "media";
                mode = "0775";
              }
              {
                directory = "/data/downloads";
                user = "root";
                group = "media";
                mode = "0775";
              }
            ];

            networking.hostName = "framebox";
            system.stateVersion = "26.05";
          };
      };
    };
  };
}
