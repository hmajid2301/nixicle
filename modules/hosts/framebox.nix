{ inputs, den, ... }:
{
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
        ../../hosts/framebox/hardware-configuration.nix
        ../../hosts/framebox/disks.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ../../hosts/framebox/facter.json; }
        inputs.nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
      ];

      sops.secrets = {
        gitlab_runner_env.sopsFile = ../../hosts/framebox/secrets.yaml;
        user_password = {
          sopsFile = ../../hosts/framebox/secrets.yaml;
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
