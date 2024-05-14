{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.security.nixicle.doas;
in {
  options.security.nixicle.doas = {
    enable = mkBoolOpt false "Whether or not to replace sudo with doas.";
  };

  config = mkIf cfg.enable {
    # Disable sudo
    security.sudo.enable = false;

    # Enable and configure `doas`.
    security.doas = {
      enable = true;
      extraRules = [
        {
          users = [config.user.name];
          noPass = true;
          keepEnv = true;
        }
      ];
    };

    # Add an alias to the shell for backward-compat and convenience.
    environment.shellAliases = {sudo = "doas";};
  };
}
