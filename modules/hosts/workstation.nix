{ inputs, den, ... }:
{
  den.aspects.workstation = {
    includes = [
      den.aspects.nfs-truenas
      den.aspects.impermanence
      den.aspects.boot-secure
    ];

    nixos = { config, ... }: {
      imports = [
        ../../hosts/workstation/hardware-configuration.nix
        ../../hosts/workstation/disks.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ../../hosts/workstation/facter.json; }
      ];

      sops.secrets = {
        user_password = {
          sopsFile = ../../hosts/workstation/secrets.yaml;
          neededForUsers = true;
        };
      };

      users.users.haseeb.hashedPasswordFile = config.sops.secrets.user_password.path;

      users.groups.media.gid = 3000;
      users.users.haseeb.extraGroups = [ "media" ];

      boot.kernelParams = [ "resume_offset=533760" ];

      # Persist secure boot keys
      environment.persistence."/persist".directories = [ "/etc/secureboot" ];

      services = {
        virtualisation.kvm.enable = true;
        virtualisation.docker.enable = true;
        nixicle.tailscale.enable = true;
      };

      networking.hostName = "workstation";
      system.stateVersion = "24.05";
    };
  };
}
