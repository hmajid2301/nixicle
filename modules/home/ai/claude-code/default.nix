{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.dev.claude-code;
in
{
  options.dev.claude-code = {
    enable = mkBoolOpt true "Enable Claude Code with MCP servers";

    extraMcpServers = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional MCP servers to configure";
      example = literalExpression ''
        {
          github = {
            command = "docker";
            args = [
              "run"
              "-i"
              "--rm"
              "-e"
              "GITHUB_PERSONAL_ACCESS_TOKEN"
              "ghcr.io/github/github-mcp-server"
            ];
          };
        }
      '';
    };

    extraSettings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional settings for Claude Code settings.json";
    };
  };

  config = mkIf cfg.enable {
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
      }
      // cfg.extraSettings;

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
          command = "uvx";
          args = [ "mcp-nixos" ];
        };

        playwright = {
          command = "${inputs.nix-playwright-mcp.packages.${pkgs.stdenv.hostPlatform.system}.playwright-mcp-wrapper}/bin/playwright-mcp";
          args = [];
        };

        zellij = {
          command = "${pkgs.nixicle.zellij-mcp}/bin/zellij-mcp";
          args = [];
        };

        postgres = {
          command = "uvx";
          args = [
            "postgres-mcp"
            "--access-mode=unrestricted"
          ];
          # Set DATABASE_URI in your shell/direnv before running claude
        };

        # zellij = {
        #   command = "${pkgs.bun}/bin/bun";
        #   args = [ "run" "${inputs.zellij-pane-tracker}/mcp-server/index.ts" ];
        # };
      }
      // cfg.extraMcpServers;
    };

    home.packages = with pkgs; [
      uv
    ];

    # Copy agent definitions to Claude Code's agents directory
    home.file = let
      agentDir = ../agents;
      agentFiles = builtins.readDir agentDir;
      agentNames = builtins.attrNames (lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".md" name) agentFiles);
      mkAgentEntry = name: {
        name = ".claude/agents/${name}";
        value = {
          source = agentDir + "/${name}";
        };
      };
    in
      builtins.listToAttrs (map mkAgentEntry agentNames);
  };
}
