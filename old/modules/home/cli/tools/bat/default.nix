{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.bat;
in
{
  options.cli.tools.bat = with types; {
    enable = mkBoolOpt false "Whether or not to enable bat";
  };

  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;
    };
  };
}
