{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.nixicle.user;
in {
  options.nixicle.user = {
    enable = mkOpt types.bool false "Whether to configure the user account.";
    home = mkOpt (types.nullOr types.str) "/home/${cfg.name}" "The user's home directory.";
    name = mkOpt (types.nullOr types.str) config.snowfallorg.user.name "The user account.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.name != null;
          message = "nixicle.user.name must be set";
        }
      ];

      home = {
        homeDirectory = mkDefault cfg.home;
        username = mkDefault cfg.name;
      };
    }
  ]);
}
