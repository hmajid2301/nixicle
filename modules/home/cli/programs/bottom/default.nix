{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle; let
  cfg = config.cli.programs.bottom;
in {
  options.cli.programs.bottom = with types; {
    enable = mkBoolOpt false "Whether or not to enable bottom";
  };

  config = mkIf cfg.enable {
    programs.bottom = {
      enable = true;
      catppuccin.enable = true;
    };
  };
}
