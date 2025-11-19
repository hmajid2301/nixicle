{
  pkgs,
  config,
  lib,
mkOpt ? null,
mkBoolOpt ? null,
enabled ? null,
disabled ? null,
  ...
}:
with lib;
 let
  cfg = config.cli.tools.zoxide;
in {
  options.cli.tools.zoxide = with types; {
    enable = mkBoolOpt false "Whether or not to enable zoxide";
  };

  config = mkIf cfg.enable {
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
  };
}
