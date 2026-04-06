{ den, inputs, ... }:
let
  agentDir = ./agents;
  agentFiles = builtins.readDir agentDir;
  agentNames = builtins.filter (name: builtins.match ".*\\.md" name != null)
    (builtins.attrNames agentFiles);
in
{
  flake-file.inputs.get-shit-done = {
    url = "github:gsd-build/get-shit-done/v1.21.1";
    flake = false;
  };
  flake-file.inputs.zellij-mcp = {
    url = "github:GitJuhb/zellij-mcp-server";
    flake = false;
  };
  flake-file.inputs.nix-playwright-mcp = {
    url = "github:benjaminkitt/nix-playwright-mcp";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.opencode-antigravity-auth = {
    url = "github:NoeFabris/opencode-antigravity-auth/v1.6.0";
    flake = false;
  };

  den.aspects.ai = {
    homeManager =
      { config, lib, pkgs, ... }:
      let
        gsdPackage = pkgs.nixicle.get-shit-done;
      in
      {
        # GSD (Get Shit Done) — Claude Code + OpenCode workflow tool

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
        } // builtins.listToAttrs (
          map (name: {
            name = ".claude/agents/${name}";
            value = { source = agentDir + "/${name}"; };
          }) agentNames
        );

        # Claude Code
        programs.claude-code = {
          enable = true;

          settings = {
            "env" = {
              "CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY" = "1";
              "DISABLE_TELEMETRY" = "1";
              "DISABLE_ERROR_REPORTING" = "1";
              "DISABLE_NON_ESSENTIAL_MODEL_CALLS" = "1";
              "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" = "true";
            };
            "includeCoAuthoredBy" = false;
            "alwaysThinkingEnabled" = false;
            hooks.SessionStart = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "node";
                    args = [ "${config.home.homeDirectory}/.claude/hooks/gsd-check-update.js" ];
                  }
                ];
              }
            ];
            statusline = {
              command = "node";
              args = [ "${config.home.homeDirectory}/.claude/hooks/gsd-statusline.js" ];
            };
          };

          mcpServers = {
            filesystem = {
              command = "npx";
              args = [
                "-y"
                "@modelcontextprotocol/server-filesystem"
                config.home.homeDirectory
              ];
            };
            nixos = {
              command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
              args = [ ];
            };
            playwright = {
              command = "${inputs.nix-playwright-mcp.packages.${pkgs.stdenv.hostPlatform.system}.playwright-mcp-wrapper}/bin/playwright-mcp";
              args = [ ];
            };
            zellij = {
              command = "${pkgs.nixicle.zellij-mcp}/bin/zellij-mcp";
              args = [ ];
            };
            postgres = {
              command = "uvx";
              args = [ "postgres-mcp" "--access-mode=unrestricted" ];
            };
          };
        };

        # OpenCode
        programs.opencode = {
          enable = true;

          commands.session-summary = "Summarize this session. First ask: personal or work? Based on answer, create notes at ~/projects/notes/notes/{work|personal}/YYYY-MM-DD-<topic>.md with summary. Update the weekly journal at ~/projects/notes/journals/weekly/ to link it with [[filename]]. Keep it concise, bullet points, focus on what shipped.";

          settings = {
            "$schema" = "https://opencode.ai/config.json";
            model = "anthropic/claude-sonnet-4-20250514";
            autoshare = false;
            autoupdate = false;
            plugin = [ "${inputs.opencode-antigravity-auth}/plugin.js" ];
            permission = {
              read."${config.home.homeDirectory}/.config/opencode/get-shit-done/*" = "allow";
              external_directory."${config.home.homeDirectory}/.config/opencode/get-shit-done/*" = "allow";
            };
            mcp = {
              playwright = {
                type = "local";
                command = [
                  "${inputs.nix-playwright-mcp.packages.${pkgs.stdenv.hostPlatform.system}.playwright-mcp-wrapper}"
                ];
                enabled = true;
              };
              zellij = {
                type = "local";
                command = [ "${pkgs.nixicle.zellij-mcp}/bin/zellij-mcp" ];
                enabled = true;
              };
              nixos = {
                type = "local";
                command = [ "${pkgs.mcp-nixos}/bin/mcp-nixos" ];
                enabled = true;
              };
              postgres = {
                type = "local";
                command = [ "uvx" "postgres-mcp" "--access-mode=unrestricted" ];
                enabled = false;
              };
            };
            provider.google.models = {
              antigravity-gemini-3-pro = {
                name = "Gemini 3 Pro (Antigravity)";
                limit = { context = 1048576; output = 65535; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
                variants = { low.thinkingLevel = "low"; high.thinkingLevel = "high"; };
              };
              antigravity-gemini-3-flash = {
                name = "Gemini 3 Flash (Antigravity)";
                limit = { context = 1048576; output = 65536; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
                variants = {
                  minimal.thinkingLevel = "minimal"; low.thinkingLevel = "low";
                  medium.thinkingLevel = "medium"; high.thinkingLevel = "high";
                };
              };
              antigravity-claude-sonnet-4-5 = {
                name = "Claude Sonnet 4.5 (Antigravity)";
                limit = { context = 200000; output = 64000; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
              };
              antigravity-claude-sonnet-4-5-thinking = {
                name = "Claude Sonnet 4.5 Thinking (Antigravity)";
                limit = { context = 200000; output = 64000; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
                variants = {
                  low.thinkingConfig.thinkingBudget = 8192;
                  max.thinkingConfig.thinkingBudget = 32768;
                };
              };
              antigravity-claude-opus-4-5-thinking = {
                name = "Claude Opus 4.5 Thinking (Antigravity)";
                limit = { context = 200000; output = 64000; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
                variants = {
                  low.thinkingConfig.thinkingBudget = 8192;
                  max.thinkingConfig.thinkingBudget = 32768;
                };
              };
              antigravity-claude-opus-4-6-thinking = {
                name = "Claude Opus 4.6 Thinking (Antigravity)";
                limit = { context = 200000; output = 64000; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
                variants = {
                  low.thinkingConfig.thinkingBudget = 8192;
                  max.thinkingConfig.thinkingBudget = 32768;
                };
              };
              "gemini-2.5-flash" = {
                name = "Gemini 2.5 Flash (Gemini CLI)";
                limit = { context = 1048576; output = 65536; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
              };
              "gemini-2.5-pro" = {
                name = "Gemini 2.5 Pro (Gemini CLI)";
                limit = { context = 1048576; output = 65535; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
              };
              gemini-3-flash-preview = {
                name = "Gemini 3 Flash Preview (Gemini CLI)";
                limit = { context = 1048576; output = 65536; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
              };
              gemini-3-pro-preview = {
                name = "Gemini 3 Pro Preview (Gemini CLI)";
                limit = { context = 1048576; output = 65535; };
                modalities = { input = [ "text" "image" "pdf" ]; output = [ "text" ]; };
              };
            };
            provider.ollama = {
              npm = "@ai-sdk/openai-compatible";
              name = "Ollama (local)";
              options.baseURL = "http://localhost:11434/v1";
              models = {
                "llama3.1:70b-instruct-q4_K_M".name = "Llama 3.1 70B (32k context)";
                "deepseek-coder:33b".name = "DeepSeek Coder 33B (32k context)";
                "codestral:22b".name = "Codestral 22B (32k context)";
              };
            };
          };
        };

        programs.opencode.agents = builtins.listToAttrs (
          map (name: {
            name = lib.removeSuffix ".md" name;
            value = agentDir + "/${name}";
          }) agentNames
        );

        home.packages = with pkgs; [
          uv
          gemini-cli
          crush
          amazon-q-cli
          gsdPackage
        ];
      };
  };
}
