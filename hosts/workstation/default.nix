{
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
  ];

  sops.secrets = {
    user_password = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
  };

  user.passwordSecretFile = config.sops.secrets.user_password.path;

  users.groups.media = {
    gid = 3000;
  };

  users.users.haseeb.extraGroups = [ "media" ];

  system = {
    impermanence.enable = true;
    boot = {
      enable = true;
      secureBoot = true;
    };
  };

  services = {
    virtualisation.kvm.enable = true;
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

  networking.hostName = "workstation";

  # TODO: refactor this also.
  services.rpcbind.enable = true;
  fileSystems."/mnt/homelab" = {
    device = "truenas:/mnt/main/main-encrypted";
    fsType = "nfs";
    options = [
      "nfsvers=4"
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "x-systemd.requires=tailscaled.service"
      "x-systemd.after=tailscaled.service"
    ];
  };

  fileSystems."/mnt/truenas" = {
    device = "truenas:/mnt/main/main";
    fsType = "nfs";
    options = [
      "nfsvers=4"
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "x-systemd.requires=tailscaled.service"
      "x-systemd.after=tailscaled.service"
    ];
  };

  system.stateVersion = "24.05";
}
