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
  cfg = config.cli.tools.modern-unix;
in
{
  options.cli.tools.modern-unix = with types; {
    enable = mkBoolOpt false "Whether or not to enable modern unix tools";
  };

  config = mkIf cfg.enable {
    cli.tools = {
      core-tools.enable = true;
      development.enable = true;
      ai-tools.enable = true;
      homelab.enable = true;
      tui.enable = true;
    };
  };
}
