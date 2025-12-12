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
    # Enable AI coding assistants via their dedicated modules
    dev.claude-code.enable = true;
    cli.tools.opencode.enable = true;

    # Install other AI tools directly
    home.packages = with pkgs; [
      gemini-cli
      crush
      amazon-q-cli
    ];
  };
}
