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
      };
    };
  };

  networking.hostName = "framework";

  system.stateVersion = "23.11";
}
