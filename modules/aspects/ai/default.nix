{ inputs, ... }:
let
  agentDir = ./agents;
  agentFiles = builtins.readDir agentDir;
  agentNames = builtins.filter (name: builtins.match ".*\\.md" name != null) (
    builtins.attrNames agentFiles
  );
  piExtensionFiles = [
    {
      rel = "zellij.ts";
      src = ./pi/zellij.ts;
    }
    {
      rel = "footer.ts";
      src = ./pi/footer.ts;
    }
    {
      rel = "subagents.ts";
      src = ./pi/subagents.ts;
    }
    {
      rel = "plan-mode.ts";
      src = ./pi/plan-mode.ts;
    }
    {
      rel = "nvim-edit/index.ts";
      src = ./pi/nvim-edit/index.ts;
    }
    {
      rel = "lsp/index.ts";
      src = ./pi/lsp/index.ts;
    }
    {
      rel = "debug/index.ts";
      src = ./pi/debug/index.ts;
    }
    {
      rel = "security-guard.ts";
      src = ./pi/security-guard.ts;
    }
    {
      rel = "plan-tracker.ts";
      src = ./pi/plan-tracker.ts;
    }
    {
      rel = "ask-user-question.ts";
      src = ./pi/ask-user-question.ts;
    }
    {
      rel = "db.ts";
      src = ./pi/db.ts;
    }
    {
      rel = "ketch.ts";
      src = ./pi/ketch.ts;
    }
    {
      rel = "treesitter.ts";
      src = ./pi/treesitter.ts;
    }
    {
      rel = "zk.ts";
      src = ./pi/zk.ts;
    }
    {
      rel = "pi-nvim.ts";
      src = ./pi/pi-nvim.ts;
    }
    {
      rel = "synthetic-models.ts";
      src = ./pi/synthetic-models.ts;
    }
  ];
in
{
  flake-file.inputs.ketch-src = {
    url = "github:1broseidon/ketch";
    flake = false;
  };

  den.aspects.ai = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        home.file = {
          ".pi/agent/models.json".source = (pkgs.formats.json { }).generate "pi-models" {
            providers = {
              llama-swap = {
                baseUrl = "http://localhost:5800/v1";
                api = "openai-completions";
                apiKey = "sk-no-key";
                models = [
                  { id = "qwen3-coder-30b"; }
                  { id = "qwen3-coder-30b:think"; }
                  { id = "qwen25-coder-7b"; }
                  { id = "qwen3-vl:8b"; }
                ];
              };
            };
          };
          ".pi/agent/settings.json".source = (pkgs.formats.json { }).generate "pi-settings" {
            defaultProvider = "openai-codex";
            defaultModel = "gpt-5.4";
            defaultThinkingLevel = "medium";
            theme = "stylix";
            packages = [
              "git:github.com/badlogic/pi-telegram"
              "git:github.com/v2nic/pi-caveman"
              "git:github.com/cdias900/pi-superpowers"
              "npm:pi-scroll"
              "npm:@observal/pi-insights"
              "npm:@samfp/pi-memory"
            ];
            extensions = map (ext: "~/.pi/agent/extensions/${ext.rel}") piExtensionFiles;
          };

          ".pi/agent/agents" = {
            source = ./agents;
            recursive = true;
          };

          ".config/ketch/config.json".source = (pkgs.formats.json { }).generate "ketch-config" {
            backend = "searxng";
            searxng_url = "http://127.0.0.1:8082";
            limit = 5;
            cache_ttl = "72h";
            code_backend = "grepapp";
            docs_backend = "context7";
            sourcegraph_url = "https://sourcegraph.com";
          };

          ".pi/agent/themes/stylix.json".source =
            let
              s = config.lib.stylix.colors.withHashtag;
            in
            pkgs.writeText "stylix.json" (
              builtins.toJSON {
                "$schema" =
                  "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
                name = "stylix";
                vars = {
                  bg = s.base00;
                  bgLight = s.base01;
                  selection = s.base02;
                  comment = s.base03;
                  fgDark = s.base04;
                  fg = s.base05;
                  red = s.base08;
                  orange = s.base09;
                  yellow = s.base0A;
                  green = s.base0B;
                  cyan = s.base0C;
                  blue = s.base0D;
                  magenta = s.base0E;
                };
                colors = {
                  accent = "blue";
                  border = "comment";
                  borderAccent = "blue";
                  borderMuted = "fgDark";
                  success = "green";
                  error = "red";
                  warning = "yellow";
                  muted = "fgDark";
                  dim = "comment";
                  text = "";
                  thinkingText = "fgDark";
                  selectedBg = "selection";
                  userMessageBg = "bgLight";
                  userMessageText = "";
                  customMessageBg = "bgLight";
                  customMessageText = "";
                  customMessageLabel = "blue";
                  toolPendingBg = "bgLight";
                  toolSuccessBg = "bgLight";
                  toolErrorBg = "bgLight";
                  toolTitle = "blue";
                  toolOutput = "";
                  mdHeading = "yellow";
                  mdLink = "blue";
                  mdLinkUrl = "fgDark";
                  mdCode = "cyan";
                  mdCodeBlock = "";
                  mdCodeBlockBorder = "fgDark";
                  mdQuote = "fgDark";
                  mdQuoteBorder = "fgDark";
                  mdHr = "comment";
                  mdListBullet = "cyan";
                  toolDiffAdded = "green";
                  toolDiffRemoved = "red";
                  toolDiffContext = "fgDark";
                  syntaxComment = "comment";
                  syntaxKeyword = "magenta";
                  syntaxFunction = "blue";
                  syntaxVariable = "orange";
                  syntaxString = "green";
                  syntaxNumber = "cyan";
                  syntaxType = "yellow";
                  syntaxOperator = "cyan";
                  syntaxPunctuation = "fgDark";
                  thinkingOff = "comment";
                  thinkingMinimal = "blue";
                  thinkingLow = "cyan";
                  thinkingMedium = "green";
                  thinkingHigh = "yellow";
                  thinkingXhigh = "red";
                  bashMode = "orange";
                };
              }
            );

          ".pi/agent/themes/catppuccin-mocha.json".source = pkgs.writeText "catppuccin-mocha.json" (
            builtins.toJSON {
              "$schema" =
                "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
              name = "catppuccin-mocha";
              vars = {
                base = "#1e1e2e";
                mantle = "#181825";
                crust = "#11111b";
                text = "#cdd6f4";
                subtext0 = "#a6adc8";
                subtext1 = "#bac2de";
                overlay0 = "#6c7086";
                overlay1 = "#7f849c";
                overlay2 = "#9399b2";
                surface0 = "#313244";
                surface1 = "#45475a";
                surface2 = "#585b70";
                blue = "#89b4fa";
                lavender = "#b4befe";
                sapphire = "#74c7ec";
                sky = "#89dceb";
                teal = "#94e2d5";
                green = "#a6e3a1";
                yellow = "#f9e2af";
                peach = "#fab387";
                maroon = "#eba0ac";
                red = "#f38ba8";
                mauve = "#cba6f7";
                pink = "#f5c2e7";
                flamingo = "#f2cdcd";
                rosewater = "#f5e0dc";
              };
              colors = {
                accent = "mauve";
                border = "overlay1";
                borderAccent = "lavender";
                borderMuted = "overlay0";
                success = "green";
                error = "red";
                warning = "yellow";
                muted = "overlay1";
                dim = "overlay0";
                text = "";
                thinkingText = "overlay1";
                selectedBg = "surface1";
                userMessageBg = "base";
                userMessageText = "";
                customMessageBg = "mantle";
                customMessageText = "subtext0";
                customMessageLabel = "mauve";
                toolPendingBg = "mantle";
                toolSuccessBg = "#1e2e1e";
                toolErrorBg = "#2e1e1e";
                toolTitle = "lavender";
                toolOutput = "subtext0";
                mdHeading = "peach";
                mdLink = "blue";
                mdLinkUrl = "overlay1";
                mdCode = "sky";
                mdCodeBlock = "";
                mdCodeBlockBorder = "overlay0";
                mdQuote = "overlay1";
                mdQuoteBorder = "overlay0";
                mdHr = "overlay0";
                mdListBullet = "teal";
                toolDiffAdded = "green";
                toolDiffRemoved = "red";
                toolDiffContext = "overlay1";
                syntaxComment = "overlay0";
                syntaxKeyword = "mauve";
                syntaxFunction = "blue";
                syntaxVariable = "text";
                syntaxString = "green";
                syntaxNumber = "peach";
                syntaxType = "yellow";
                syntaxOperator = "sky";
                syntaxPunctuation = "overlay1";
                thinkingOff = "overlay0";
                thinkingMinimal = "blue";
                thinkingLow = "sapphire";
                thinkingMedium = "teal";
                thinkingHigh = "yellow";
                thinkingXhigh = "peach";
                bashMode = "peach";
              };
            }
          );
        }
        // builtins.listToAttrs (
          map (name: {
            name = ".claude/agents/${name}";
            value = {
              source = agentDir + "/${name}";
            };
          }) agentNames
        )
        // builtins.listToAttrs (
          map (ext: {
            name = ".pi/agent/extensions/${ext.rel}";
            value.source = ext.src;
          }) piExtensionFiles
        );

        programs = {
          claude-code = {
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

        home.packages = with pkgs; [
          gh
          glab
          ddgr
          nixicle.ketch
          (pi-coding-agent.overrideAttrs (_old: {
            postFixup = ''
              wrapProgram $out/bin/pi \
                --prefix PATH : ${lib.makeBinPath [ ripgrep ]} \
                --set NPM_CONFIG_PREFIX "$HOME/.pi/npm" \
                --set npm_config_prefix "$HOME/.pi/npm"
            '';
          }))
        ];
      };
  };
}
