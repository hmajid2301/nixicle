{ inputs, den, ... }:
{
  den.aspects.framework = {
    nixos = { config, lib, pkgs, ... }: {
      imports = [
        ../../hosts/framework/hardware-configuration.nix
        ../../hosts/framework/disks.nix
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ../../hosts/framework/facter.json; }
        inputs.nixos-hardware.nixosModules.framework-13-7040-amd
      ];

      sops.secrets = {
        user_password = {
          sopsFile = ../../hosts/framework/secrets.yaml;
          neededForUsers = true;
        };
      };

      users.users.haseeb.hashedPasswordFile = config.sops.secrets.user_password.path;

      security.nixicle.pcr-verification = {
        enable = true;
        expectedPcr15 = "caf33e79c645b65849256238a11fa68ae197e5cb89730c463c1cdf1d9128376f";
      };

      system = {
        impermanence.enable = true;
        boot = {
          enable = true;
          secureBoot = true;
        };
      };

      networking.hostName = "framework";
      system.stateVersion = "23.11";
    };
  };
}
