{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.programs.ai-tools;
in
{
  options.cli.programs.ai-tools = with types; {
    enable = mkBoolOpt false "Whether or not to enable AI tools and assistants";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # AI coding assistants
      opencode
      claude-code
      gemini-cli
      crush

      # Amazon Q Developer (uncomment when confirmed available in nixpkgs)
      # amazon-q-developer
    ];
  };
}