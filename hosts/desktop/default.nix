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
    ];

    homeManager =
      { ... }:
      {
        home = {
          username = "haseeb";
          homeDirectory = "/home/haseeb";
          stateVersion = "24.05";
        };

        programs.noctalia-shell.settings.idle = {
          enabled = true;
          screenOffTimeout = 330;
          lockTimeout = 300;
          suspendTimeout = 1800;
          fadeDuration = 5;
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
        ];

        sops.defaultSopsFile = ./secrets.yaml;

        sops.secrets = {
          user_password = {
            neededForUsers = true;
          };
          searx_secret_key = { };
          gitlab_runner_env = { };
        };

        users = {
          users.haseeb.hashedPasswordFile = config.sops.secrets.user_password.path;
          groups.media.gid = 3000;
          users.haseeb.extraGroups = [
            "wheel"
            "media"
          ];
          extraGroups.docker.members = [ "haseeb" ];
        };

        boot = {
          kernelParams = [ "resume_offset=533760" ];
          kernel.sysctl."net.ipv4.ip_forward" = 1;
        };

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

        environment.systemPackages = with pkgs; [
          docker-compose
        ];

        networking.hostName = "desktop";
        system.stateVersion = "24.05";
      };
  };
}
