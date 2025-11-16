{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.ai-tools;
in
{
  options.cli.tools.ai-tools = with types; {
    enable = mkBoolOpt false "Whether or not to enable AI tools and assistants";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
      claude-code
      gemini-cli
      crush
      amazon-q-cli
    ];
   };
}
