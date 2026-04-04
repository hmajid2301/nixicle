{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.bottom;
in
{
  options.cli.tools.bottom = with types; {
    enable = mkBoolOpt false "Whether or not to enable bottom";
  };

  config = mkIf cfg.enable {
    programs.bottom = {
      enable = true;
    };
  };
}
