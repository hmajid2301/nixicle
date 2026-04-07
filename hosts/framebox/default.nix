{ inputs, den, lib, ... }:
{
  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den = {
    aspects = {
      haseeb = {
        includes = [
          ({ user, ... }: {
            nixos = {
              users.users.haseeb.openssh.authorizedKeys.keys = user.authorizedKeys;
              users.users.root.openssh.authorizedKeys.keys = user.authorizedKeys;
              home-manager.users.haseeb.programs.git = {
                settings.user.email = lib.mkForce user.email;
                signing.key = lib.mkForce user.signingKey;
              };
            };
          })
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
          den.aspects.video
        ];

        homeManager = { pkgs, config, ... }: {
          home = {
            username = "haseeb";
            homeDirectory = "/home/haseeb";
            stateVersion = "24.05";
          };

          services.swayidle = {
            enable = true;
            events.before-sleep = "noctalia-shell ipc call lockScreen lock";
            timeouts = [
              { timeout = 300; command = "noctalia-shell ipc call lockScreen lock"; }
              {
                timeout = 330;
                command = "${config.programs.niri.package}/bin/niri msg action power-off-monitors";
                resumeCommand = "${config.programs.niri.package}/bin/niri msg action power-on-monitors";
              }
            ];
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
          den.aspects.gitea
          den.aspects.goroutinely
          den.aspects.gitlab-runner
          den.aspects.immich
          den.aspects.karakeep
          den.aspects.llama-cpp
          den.aspects.ollama
          den.aspects.monitoring
          den.aspects.open-webui
          den.aspects.otel-collector
          den.aspects.redis
          den.aspects.postgresql
          den.aspects.paperless
          den.aspects.tangled
          den.aspects.tandoor
          den.aspects.papra
          den.aspects.bentopdf
          den.aspects.hortusfox
          den.aspects.trek
        ];

        nixos = { config, lib, ... }: {
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
            users.haseeb.hashedPasswordFile = config.sops.secrets.user_password.path;
            groups.media.gid = 3000;
            users.haseeb.extraGroups = [ "media" ];
          };

          environment.persistence."/persist".directories = [ "/etc/secureboot" ];

          networking.hostName = "framebox";
          system.stateVersion = "24.05";
        };
      };
    };
  };
}
