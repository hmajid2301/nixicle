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
      ".claude/commands/gsd".source = "${gsdPackage}/share/claude-code/commands/gsd";
      ".claude/get-shit-done".source = "${gsdPackage}/share/claude-code/get-shit-done";
      ".claude/agents" = {
        source = "${gsdPackage}/share/claude-code/agents";
        recursive = true;
      };
      ".claude/hooks".source = "${gsdPackage}/share/claude-code/hooks";

      ".config/opencode/command" = {
        source = "${gsdPackage}/share/opencode/command";
        recursive = true;
      };
      ".config/opencode/get-shit-done".source = "${gsdPackage}/share/opencode/get-shit-done";
      ".config/opencode/agents" = {
        source = "${gsdPackage}/share/opencode/agents";
        recursive = true;
      };
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
      permission = {
        read = {
          "${config.home.homeDirectory}/.config/opencode/get-shit-done/*" = "allow";
        };
        external_directory = {
          "${config.home.homeDirectory}/.config/opencode/get-shit-done/*" = "allow";
        };
      };
    };
  };
}
