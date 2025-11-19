{delib, ...}:
delib.module {
  name = "cli-tools-ai-tools";

  options.cli.tools.ai-tools = with delib; {
    enable = boolOption false;
  };

  home.always = {config, lib, pkgs, ...}:
  with lib;
  with lib.nixicle;
  let
    cfg = config.cli.tools.ai-tools;
  in
  mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
      claude-code
      gemini-cli
      crush
      amazon-q-cli
    ];
   };
}
