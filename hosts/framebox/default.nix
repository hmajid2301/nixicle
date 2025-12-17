{
  pkgs,
  inputs,
  config,
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

  networking.hostName = "framebox";

  system = {
    impermanence.enable = true;
    boot = {
      enable = true;
      secureBoot = true;
    };
  };

  sops.secrets = {
    gitlab_runner_env = {
      sopsFile = ./secrets.yaml;
    };
  };

  services = {
    nixicle = {
      atuin.enable = true;
      atticd.enable = true;
      ollama.enable = true;
      gitlab-runner = {
        enable = true;
        sopsFile = config.sops.secrets.gitlab_runner_env.path;
      };
      cloudflare = {
        enable = true;
        tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
        credentialsFile = "/home/${config.user.name}/.cloudflared/ecef5dbb-834e-43ed-84c6-355a2ac53e59.json";
      };
      traefik.enable = true;
    };
  };

  roles = {
    desktop = {
      enable = true;
      addons = {
        niri.enable = true;
      };
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    resumeDevice = "/dev/disk/by-label/nixos";
  };

  system.stateVersion = "24.05";
}
