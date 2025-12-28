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

  sops.secrets = {
    gitlab_runner_env = {
      sopsFile = ./secrets.yaml;
    };
    cloudflared = {
      sopsFile = ./secrets.yaml;
    };
    user_password = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
  };

  user.passwordSecretFile = config.sops.secrets.user_password.path;

  system = {
    impermanence.enable = true;
    boot = {
      enable = true;
      secureBoot = true;
    };
  };

  services = {
    power-profiles-daemon.enable = true;
    nixicle = {
      authentik.enable = true;
      atuin.enable = true;
      atticd.enable = true;
      cloudflare = {
        enable = true;
        tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
        credentialsFile = config.sops.secrets.cloudflared.path;
      };
      gitea.enable = true;
      gitlab-runner = {
        enable = true;
        sopsFile = config.sops.secrets.gitlab_runner_env.path;
      };
      karakeep.enable = true;
      tandoor.enable = true;
      redis.enable = true;
      traefik.enable = true;
      paperless = {
        enable = true;
        mediaDir = "/mnt/truenas/homelab/paperless/media";
      };
      postgresql.enable = true;
      tailscale.enable = true;
      llama-cpp.enable = true;
      open-webui.enable = true;
      crowdsec.enable = true;
    };
  };

  roles = {
    desktop = {
      enable = true;
      addons = {
        niri.enable = true;
      };
    };
    gaming.enable = true;
  };

  networking.hostName = "framebox";

  services.rpcbind.enable = true;
  fileSystems."/mnt/truenas" = {
    device = "192.168.1.152:/mnt/main/main-encrypted";
    fsType = "nfs";
    options = [
      "nfsvers=4"
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
    ];
  };

  system.stateVersion = "24.05";
}
