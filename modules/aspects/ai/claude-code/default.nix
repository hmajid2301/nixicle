_: {
  den.aspects.claude-code = {
    homeManager =
      {
        config,
        pkgs,
        ...
      }:
      {
        home.file = builtins.listToAttrs (
          map
            (name: {
              name = ".claude/agents/${name}";
              value = {
                source = ../agents + "/${name}";
              };
            })
            (
              builtins.filter (name: builtins.match ".*\\.md" name != null) (
                builtins.attrNames (builtins.readDir ../agents)
              )
            )
        );

        programs.claude-code = {
          enable = true;

          settings = {
            env = {
              CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
              DISABLE_TELEMETRY = "1";
              DISABLE_ERROR_REPORTING = "1";
              DISABLE_NON_ESSENTIAL_MODEL_CALLS = "1";
              CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "true";
            };
            includeCoAuthoredBy = false;
            alwaysThinkingEnabled = false;

            hooks.SessionStart = [
              {
                matcher = "*";
                hooks = [
                  {
                    type = "command";
                    command = "bash '${config.home.homeDirectory}/.claude/hooks/herdr-agent-state.sh' session";
                    timeout = 10;
                  }
                ];
              }
            ];
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
          };
        };
      };
  };
}
