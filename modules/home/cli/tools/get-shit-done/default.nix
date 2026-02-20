{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.get-shit-done;
  gsdPackage = pkgs.callPackage ../../../../../packages/get-shit-done { };
in
{
  options.cli.tools.get-shit-done = with types; {
    enable = mkBoolOpt false "Whether or not to enable Get Shit Done for Claude Code and OpenCode";
  };

  config = mkIf cfg.enable {
    home.packages = [ gsdPackage ];

    home.file = {
      ".claude/commands/gsd".source = "${gsdPackage}/share/claude-code/get-shit-done/commands";
      ".claude/get-shit-done".source = "${gsdPackage}/share/claude-code/get-shit-done/get-shit-done";
      ".claude/agents/gsd" = {
        source = "${gsdPackage}/share/claude-code/get-shit-done/agents";
        recursive = true;
      };
      ".claude/hooks/gsd-check-update.js".source = "${gsdPackage}/share/claude-code/get-shit-done/hooks/gsd-check-update.js";
      ".claude/hooks/gsd-statusline.js".source = "${gsdPackage}/share/claude-code/get-shit-done/hooks/gsd-statusline.js";

      ".config/opencode/commands/gsd".source = "${gsdPackage}/share/claude-code/get-shit-done/commands";
      ".config/opencode/get-shit-done".source = "${gsdPackage}/share/claude-code/get-shit-done/get-shit-done";
      ".config/opencode/agents/gsd" = {
        source = "${gsdPackage}/share/claude-code/get-shit-done/agents";
        recursive = true;
      };
      ".config/opencode/hooks/gsd-check-update.js".source = "${gsdPackage}/share/claude-code/get-shit-done/hooks/gsd-check-update.js";
      ".config/opencode/hooks/gsd-statusline.js".source = "${gsdPackage}/share/claude-code/get-shit-done/hooks/gsd-statusline.js";
    };

    dev.claude-code.extraSettings = {
      hooks.SessionStart = [
        {
          command = "node";
          args = [ "${config.home.homeDirectory}/.claude/hooks/gsd-check-update.js" ];
        }
      ];
      statusline = {
        command = "node";
        args = [ "${config.home.homeDirectory}/.claude/hooks/gsd-statusline.js" ];
      };
    };

    cli.tools.opencode.extraSettings = {
      read = [
        "${config.home.homeDirectory}/.config/opencode/get-shit-done/**"
        "${config.home.homeDirectory}/.planning/**"
      ];
    };
  };
}
