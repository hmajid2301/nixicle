{ inputs, den, lib, ... }:
{
  den.aspects.haseeb = {
    includes = [
      ({ user, ... }: {
        nixos.users.users.haseeb.openssh.authorizedKeys.keys = user.authorizedKeys;
        nixos.users.users.root.openssh.authorizedKeys.keys = user.authorizedKeys;
        nixos.home-manager.users.haseeb.programs.git = {
          settings.user.email = lib.mkForce user.email;
          signing.key = lib.mkForce user.signingKey;
        };
      })
    ];

    homeManager = { ... }: {
      gtk.gtk4.theme = null;
      programs.git.signing = {
        format = "ssh";
        signByDefault = true;
      };
    };
  };

  den.aspects.haseeb.provides.framebox = {
    includes = [
      den.aspects.desktop
      den.aspects.gaming
      den.aspects.social
      den.aspects.video
    ];

    homeManager = { ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "24.05";
      };

      desktops = {
        niri.enable = true;
        addons = {
          noctalia.enable = true;
          swayidle = {
            enable = true;
            timeouts = {
              lock = 300;
              dpms = 330;
              suspend = 0;
              hibernate = 0;
            };
          };
        };
      };
    };
  };

  den.aspects.framebox = {
    includes = [
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

      users.users.haseeb.hashedPasswordFile = config.sops.secrets.user_password.path;

      users.groups.media.gid = 3000;
      users.users.haseeb.extraGroups = [ "media" ];

      services.power-profiles-daemon.enable = true;

      environment.persistence."/persist".directories = [ "/etc/secureboot" ];

      networking.hostName = "framebox";
      system.stateVersion = "24.05";
    };
  };
}
