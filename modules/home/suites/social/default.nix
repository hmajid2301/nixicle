{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.suites.social;
in {
  options.suites.social = {
    enable = mkEnableOption "Enable social suite";
  };

  config = mkIf cfg.enable {
    programs = {
      discord.enable = true;
      shotwell.enable = true;
    };
  };
}
