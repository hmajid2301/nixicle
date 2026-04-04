{ inputs, den, ... }:
{
  den.aspects.framebox = {
    includes = [ den.aspects.nfs-truenas ];

    nixos = { config, ... }: {
      imports = [
        ../../hosts/framebox/hardware-configuration.nix
        ../../hosts/framebox/disks.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ../../hosts/framebox/facter.json; }
        inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
      ];

      sops.secrets = {
        gitlab_runner_env.sopsFile = ../../hosts/framebox/secrets.yaml;
        cloudflared.sopsFile = ../../hosts/framebox/secrets.yaml;
        user_password = {
          sopsFile = ../../hosts/framebox/secrets.yaml;
          neededForUsers = true;
        };
        b2_access_key.sopsFile = ../../hosts/framebox/secrets.yaml;
        b2_secret_key.sopsFile = ../../hosts/framebox/secrets.yaml;
      };

      users.users.haseeb.hashedPasswordFile = config.sops.secrets.user_password.path;

      users.groups.media.gid = 3000;
      users.users.haseeb.extraGroups = [ "media" ];

      system = {
        impermanence.enable = true;
        boot = {
          enable = true;
          secureBoot = true;
        };
      };

      services = {
        power-profiles-daemon.enable = true;
        virtualisation.kvm.enable = true;

        nixicle = {
          authentik.enable = true;
          atuin.enable = true;
          atticd.enable = true;

          banterbus = {
            enable = true;
            instances = {
              dev = {
                port = 8084;
                domain = "dev.banterbus.games";
              };
              prod = {
                port = 8083;
                domain = "banterbus.games";
              };
            };
          };

          btrbk = {
            enable = true;
            instances.local = {
              onCalendar = "weekly";
              subvolumes = {
                "/persist" = {
                  target = "/mnt/truenas/backups/framebox/persist";
                  snapshot_dir = ".snapshots";
                };
                "/home" = {
                  target = "/mnt/truenas/backups/framebox/home";
                  snapshot_dir = ".snapshots";
                };
              };
              retention = {
                weekly = 2;
                monthly = 6;
              };
            };
            backblaze = {
              enable = true;
              bucket = "Majiy00Homelab";
              endpoint = "s3.us-west-004.backblazeb2.com";
              paths = [
                "/persist/.snapshots"
                "/home/.snapshots"
              ];
              onCalendar = "weekly";
            };
          };

          cloudflare = {
            enable = true;
            tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
            credentialsFile = config.sops.secrets.cloudflared.path;
          };

          crowdsec.enable = true;
          gitea.enable = true;
          goroutinely.enable = true;

          gitlab-runner = {
            enable = true;
            sopsFile = config.sops.secrets.gitlab_runner_env.path;
          };

          immich = {
            enable = true;
            mediaLocation = "/mnt/homelab/homelab/immich";
          };

          karakeep.enable = true;

          llama-cpp.enable = true;

          ollama = {
            enable = true;
            acceleration = "vulkan";
            vulkan = {
              flashAttention = true;
              kvCacheType = "q8_0";
              contextLength = 64000;
            };
          };

          monitoring.enable = true;
          open-webui.enable = true;
          otel-collector.enable = true;
          redis.enable = true;
          postgresql.enable = true;

          paperless = {
            enable = true;
            mediaDir = "/mnt/homelab/homelab/paperless/media";
          };

          tangled.enable = true;
          tandoor.enable = true;
          traefik.enable = true;
          tailscale.enable = true;
          papra.enable = true;
          bentopdf.enable = true;
          hortusfox.enable = true;
          trek.enable = true;
        };
      };

      networking.hostName = "framebox";
      system.stateVersion = "24.05";
    };
  };
}
