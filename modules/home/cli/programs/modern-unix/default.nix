{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.programs.modern-unix;
in
{
  options.cli.programs.modern-unix = with types; {
    enable = mkBoolOpt false "Whether or not to enable modern unix tools";
  };

  config = mkIf cfg.enable {
    cli.programs = {
      core-tools.enable = true;
      development.enable = true;
      ai-tools.enable = true;
      homelab.enable = true;
      tui.enable = true;
    };
  };
}
