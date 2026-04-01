# framework host aspect — extends the auto-created den.aspects.framework.
{ den, inputs, ... }:
{
  den.aspects.framework = {
    includes = [
      den.aspects.desktop
      den.provides.primary-user
    ];

    nixos = { config, ... }: {
      imports = [
        inputs.nixos-facter-modules.nixosModules.facter
        { config.facter.reportPath = ../../../hosts/framework/facter.json; }
      ];

      sops.secrets.user_password = {
        sopsFile = ../../../hosts/framework/secrets.yaml;
        neededForUsers = true;
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

      roles.desktop = {
        enable = true;
        addons = {
          niri.enable = true;
          greetd.autologin = false;
        };
      };

      system.stateVersion = "23.11";
    };
  };
}
