{
  config,
  lib,
  inputs,
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
      default = { };
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
      default = { };
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
        autoshare = false;
        autoupdate = false;
        mcp = {
          zellij = {
            type = "local";
            command = [
              "${pkgs.bun}/bin/bun"
              "run"
              "${inputs.zellij-pane-tracker}/mcp-server/index.ts"
            ];
            enabled = true;
          };
        };
        provider = {
          ollama = {
            npm = "@ai-sdk/openai-compatible";
            name = "Ollama (local)";
            options = {
              baseURL = "http://localhost:11434/v1";
            };
            models = {
              "llama3.1:70b-instruct-q4_K_M" = {
                name = "Llama 3.1 70B (32k context)";
              };
              "deepseek-coder:33b" = {
                name = "DeepSeek Coder 33B (32k context)";
              };
              "codestral:22b" = {
                name = "Codestral 22B (32k context)";
              };
            };
          };
        };
      }
      // cfg.extraSettings;
    };
  };
}
