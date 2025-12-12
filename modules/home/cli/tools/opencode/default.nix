{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.cli.tools.opencode;
in
{
  options.cli.tools.opencode = {
    enable = mkBoolOpt true "Enable OpenCode terminal-based AI coding assistant";

    extraCommands = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional custom commands for OpenCode";
      example = literalExpression ''
        {
          changelog = '''
            # Update Changelog Command
            Update CHANGELOG.md with a new entry for the specified version.
            Usage: /changelog [version] [change-type] [message]
          ''';
          commit = '''
            # Commit Command
            Create a git commit with proper message formatting.
          ''';
        }
      '';
    };

    extraSettings = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional settings for OpenCode config.json";
      example = literalExpression ''
        {
          autoshare = true;
          autoupdate = false;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      commands = cfg.extraCommands;

      settings = {
        model = "anthropic/claude-sonnet-4-20250514";
        telemetry = false;
        autoshare = false;
        autoupdate = false;
      } // cfg.extraSettings;
    };
  };
}
