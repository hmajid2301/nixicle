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

        "$schema" = "https://opencode.ai/config.json";
        plugin = [ "opencode-antigravity-auth@latest" ];
        provider.google.models = {
          antigravity-gemini-3-pro = {
            name = "Gemini 3 Pro (Antigravity)";
            limit = {
              context = 1048576;
              output = 65535;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            variants = {
              low.thinkingLevel = "low";
              high.thinkingLevel = "high";
            };
          };
          antigravity-gemini-3-flash = {
            name = "Gemini 3 Flash (Antigravity)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            variants = {
              minimal.thinkingLevel = "minimal";
              low.thinkingLevel = "low";
              medium.thinkingLevel = "medium";
              high.thinkingLevel = "high";
            };
          };
          antigravity-claude-sonnet-4-5 = {
            name = "Claude Sonnet 4.5 (Antigravity)";
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          antigravity-claude-sonnet-4-5-thinking = {
            name = "Claude Sonnet 4.5 Thinking (Antigravity)";
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            variants = {
              low.thinkingConfig.thinkingBudget = 8192;
              max.thinkingConfig.thinkingBudget = 32768;
            };
          };
          antigravity-claude-opus-4-5-thinking = {
            name = "Claude Opus 4.5 Thinking (Antigravity)";
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            variants = {
              low.thinkingConfig.thinkingBudget = 8192;
              max.thinkingConfig.thinkingBudget = 32768;
            };
          };
          antigravity-claude-opus-4-6-thinking = {
            name = "Claude Opus 4.6 Thinking (Antigravity)";
            limit = {
              context = 200000;
              output = 64000;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
            variants = {
              low.thinkingConfig.thinkingBudget = 8192;
              max.thinkingConfig.thinkingBudget = 32768;
            };
          };
          "gemini-2.5-flash" = {
            name = "Gemini 2.5 Flash (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          "gemini-2.5-pro" = {
            name = "Gemini 2.5 Pro (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          gemini-3-flash-preview = {
            name = "Gemini 3 Flash Preview (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65536;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
          };
          gemini-3-pro-preview = {
            name = "Gemini 3 Pro Preview (Gemini CLI)";
            limit = {
              context = 1048576;
              output = 65535;
            };
            modalities = {
              input = [
                "text"
                "image"
                "pdf"
              ];
              output = [ "text" ];
            };
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
