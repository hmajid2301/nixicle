{
  inputs,
  den,
  ...
}:
{
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den.aspects.haseeb.provides.desktop = {
    includes = [
      den.aspects.desktopProfile
      den.aspects.gaming
      den.aspects.social
      den.aspects.video
      den.aspects.helix
    ];

    homeManager =
      { pkgs, ... }:
      {
        home = {
          username = "haseeb";
          homeDirectory = "/home/haseeb";
          stateVersion = "24.05";
          packages = [ pkgs.mutagen ];
        };

        programs.noctalia.settings.idle = {
          pre_action_fade_seconds = 5.0;
          behavior = {
            lock = {
              timeout = 300;
              action = "lock";
            };
            screen-off = {
              timeout = 330;
              action = "screen_off";
            };
            suspend = {
              timeout = 1800;
              action = "lock_and_suspend";
            };
          };
        };

        systemd.user.services.mutagen-agent-sync = {
          Unit = {
            Description = "Sync agent transcripts with the VPS";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
            ConditionPathExists = "%h/.config/mutagen/sync-enabled";
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = pkgs.writeShellScript "mutagen-agent-sync" ''
              set -euo pipefail

              mutagen=${pkgs.mutagen}/bin/mutagen
              "$mutagen" daemon start

              ensure_sync() {
                local name="$1"
                local local_path="$2"
                local remote_path="$3"
                if "$mutagen" sync list "$name" >/dev/null 2>&1; then
                  "$mutagen" sync resume "$name" >/dev/null 2>&1 || true
                else
                  "$mutagen" sync create \
                    --name "$name" \
                    --mode two-way-safe \
                    "$local_path" \
                    "haseeb@vps:$remote_path"
                fi
              }

              ensure_sync \
                pi-sessions \
                "$HOME/.pi/agent/sessions" \
                "/home/haseeb/.pi/agent/sessions"

              ensure_sync \
                claude-projects \
                "$HOME/.claude/projects" \
                "/home/haseeb/.claude/projects"
            '';
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
  };

  den.aspects.desktop = {
    includes = [
      den.aspects.performance-max
      den.aspects.nfs-nas
      den.aspects.impermanence
      den.aspects.boot-secure
      den.aspects.tailscale
      den.aspects.kvm
      den.aspects.searx
      den.aspects.gitlab-runner
      den.aspects.backup-restic
    ];

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [
          ./hardware-configuration.nix
          ./disks.nix
          inputs.nixos-facter-modules.nixosModules.facter
          { config.facter.reportPath = ./facter.json; }
        ];

        sops.defaultSopsFile = ./secrets.yaml;
        sops.secrets = {
          user_password.neededForUsers = true;
          searx_secret_key = { };
          gitlab_runner_env = { };
        };

        system.backup.objects = {
          home = {
            paths = [ "/home/haseeb" ];
            exclude = [
              "/home/haseeb/.local/share/Trash"
              "/home/haseeb/.gomi"
              "/home/haseeb/.local/share/Steam"
              "/home/haseeb/Games"
              "/home/haseeb/.config/gtk"
              "/home/haseeb/.local/share/docker"
              "/home/haseeb/.local/cache"
              "/home/haseeb/.cache"
              "/home/haseeb/.local/share/go"
              "/home/haseeb/.local/share/pnpm"
              "**/.direnv"
              "**/node_modules"
              "**/target"
            ];
          };
          systemState = {
            paths = [
              "/persist/etc/ssh"
              "/persist/etc/secureboot"
              "/persist/etc/machine-id"
              "/persist/var/lib/bluetooth"
              "/persist/var/lib/NetworkManager"
            ];
          };
        };

        users = {
          groups.media.gid = 3000;
          users.haseeb = {
            hashedPasswordFile = config.sops.secrets.user_password.path;
            extraGroups = [
              "media"
              "i2c"
            ];
          };
          extraGroups.docker.members = [ "haseeb" ];
        };

        boot = {
          kernelParams = [ "resume_offset=533760" ];
          kernel.sysctl."net.ipv4.ip_forward" = 1;
        };

        networking.hostName = "desktop";

        virtualisation.docker = {
          enable = true;
          enableOnBoot = true;
          autoPrune.enable = true;
          storageDriver = "btrfs";
          rootless = {
            enable = true;
            setSocketVariable = true;
          };
        };

        environment.systemPackages = with pkgs; [ docker-compose ];

        fileSystems."/mnt/homelab".options = lib.mkForce [
          "nfsvers=4"
          "noatime"
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"
        ];

        fileSystems."/mnt/homelab/homelab".options = lib.mkForce [
          "nfsvers=4"
          "noatime"
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=60"
          "x-systemd.device-timeout=5s"
          "x-systemd.mount-timeout=5s"
          "x-systemd.requires=mnt-homelab.mount"
          "x-systemd.after=mnt-homelab.mount"
        ];

        system.stateVersion = "24.05";
      };
  };
}
