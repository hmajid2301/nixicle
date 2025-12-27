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
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ];

  sops.secrets = {
    user_password = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };
  };

  user.passwordSecretFile = config.sops.secrets.user_password.path;

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

  roles = {
    desktop = {
      enable = true;
      addons = {
        niri.enable = true;
        greetd.autologin = false;
      };
    };
  };

  networking.hostName = "framework";

  system.stateVersion = "23.11";
}
