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
          gtk.gtk4.theme = null;
          programs.git.signing = {
            format = "ssh";
            signByDefault = true;
          };
        };
      };

      haseeb.provides.framebox = {
        includes = [
          den.aspects.desktop
          den.aspects.gaming
          den.aspects.social
          den.aspects.obs
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
          den.aspects.nfs-truenas
          den.aspects.impermanence
          den.aspects.boot-secure
          den.aspects.tailscale
          den.aspects.kvm
          den.aspects.traefik
          den.aspects.cloudflare
          den.aspects.authentik
          den.aspects.atuin
          den.aspects.atticd
          den.aspects.banterbus
          den.aspects.btrbk
          den.aspects.crowdsec
          den.aspects.forgejo
          den.aspects.goroutinely
          den.aspects.garage
          den.aspects.gothreads
          den.aspects.lettucego
          den.aspects.gitlab-runner
          den.aspects.immich
          den.aspects.karakeep
          den.aspects.llama-cpp
          den.aspects.ollama
          den.aspects.open-webui
          den.aspects.otel-collector
          den.aspects.redis
          den.aspects.postgresql
          den.aspects.tandoor
          den.aspects.papra
          den.aspects.bentopdf
          den.aspects.fish
          den.aspects.monitoring
          den.aspects.homepage
          den.aspects.home-assistant
          den.aspects.zellij
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

            sops.secrets = {
              gitlab_runner_env.sopsFile = ./secrets.yaml;
              user_password = {
                sopsFile = ./secrets.yaml;
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
                  "docker"
                ];
              };
              groups.media.gid = 3000;
            };

            virtualisation = {
              docker = {
                enable = true;
                enableOnBoot = true;
                autoPrune.enable = true;
                storageDriver = "btrfs";
                rootless = {
                  enable = true;
                  setSocketVariable = true;
                };
              };
              oci-containers.backend = "docker";
            };

            # TODO: move to boot.nix in all files
            environment.persistence."/persist".directories = [
              "/etc/secureboot"
              {
                directory = "/var/lib/docker";
                user = "root";
                group = "root";
                mode = "0755";
              }
            ];

            networking.hostName = "framebox";
            system.stateVersion = "26.05";

            environment.systemPackages = with pkgs; [
              docker-compose
            ];
          };
      };
    };
  };
}
