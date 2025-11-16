{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
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
