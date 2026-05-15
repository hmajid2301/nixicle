{ inputs, ... }:
let
  agentDir = ./agents;
  agentFiles = builtins.readDir agentDir;
  agentNames = builtins.filter (name: builtins.match ".*\\.md" name != null) (
    builtins.attrNames agentFiles
  );
in
{
  flake-file.inputs = {
    get-shit-done = {
      url = "github:gsd-build/get-shit-done/v1.21.1";
      flake = false;
    };
    zellij-mcp = {
      url = "github:GitJuhb/zellij-mcp-server";
      flake = false;
    };
    zellij-pane-tracker = {
      url = "github:theslyprofessor/zellij-pane-tracker";
      flake = false;
    };
    nix-playwright-mcp = {
      url = "github:benjaminkitt/nix-playwright-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.ai = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        gsdPackage = pkgs.nixicle.get-shit-done;
      in
      {
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
                ];
              };
            };
          };
          ".pi/agent/settings.json".source = (pkgs.formats.json { }).generate "pi-settings" {
            defaultProvider = "openai-codex";
            defaultModel = "gpt-5.4";
            defaultThinkingLevel = "medium";
            packages = [
              "git:github.com/badlogic/pi-telegram"
              "git:github.com/v2nic/pi-caveman"
              "git:github.com/elpapi42/pi-observational-memory"
              "git:github.com/raphapr/pi-zk"
              "git:github.com/cdias900/pi-superpowers"
            ];
            extensions = [
              "~/.pi/agent/extensions/zellij.ts"
              "~/.pi/agent/extensions/lualine-footer.ts"
              "~/.pi/agent/extensions/subagents.ts"
              "~/.pi/agent/extensions/plan-mode.ts"
              "~/.pi/agent/extensions/stylix-theme.ts"
              "~/.pi/agent/extensions/lsp/index.ts"
              "~/.pi/agent/extensions/security-guard.ts"
              "~/.pi/agent/extensions/plan-tracker.ts"
              "~/.pi/agent/extensions/db.ts"
            ];
          };

          ".pi/agent/extensions/zellij.ts".source = ../../../packages/zellij-pi-extension/index.ts;
          ".pi/agent/extensions/lualine-footer.ts".source = ../../../packages/pi-lualine-footer/index.ts;
          ".pi/agent/extensions/subagents.ts".source = ./pi/subagents.ts;
          ".pi/agent/extensions/plan-mode.ts".source = ./pi/plan-mode.ts;
          ".pi/agent/extensions/stylix-theme.ts".source = ./pi/stylix-theme.ts;
          ".pi/agent/extensions/security-guard.ts".source = ./pi/security-guard.ts;
          ".pi/agent/extensions/plan-tracker.ts".source = ./pi/plan-tracker.ts;
          ".pi/agent/extensions/db.ts".source = ./pi/db.ts;

          # Agent files (individual symlinks to avoid overwriting entire directory)
          ".pi/agent/agents" = {
            source = ./pi/agents;
            recursive = true;
          };

          # Pi theme from stylix base16 — maps palette to all 51 color tokens
          ".pi/agent/themes/stylix.json".source =
            let
              s = config.lib.stylix.colors;
              co = base: fallback: base.withHashtag or fallback;
            in
            pkgs.writeText "stylix.json" (
              builtins.toJSON {
                "$schema" =
                  "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
                name = "stylix";
                vars = {
                  bg = co s.base00 "#282828";
                  bgLight = co s.base01 "#383838";
                  selection = co s.base02 "#505050";
                  comment = co s.base03 "#665c54";
                  fgDark = co s.base04 "#a89984";
                  fg = co s.base05 "#bdae93";
                  red = co s.base08 "#fb4934";
                  orange = co s.base09 "#fe8019";
                  yellow = co s.base0A "#fabd2f";
                  green = co s.base0B "#b8bb26";
                  cyan = co s.base0C "#8ec07c";
                  blue = co s.base0D "#83a598";
                  magenta = co s.base0E "#d3869b";
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
        }
        // builtins.listToAttrs (
          map (name: {
            name = ".claude/agents/${name}";
            value = {
              source = agentDir + "/${name}";
            };
          }) agentNames
        )
        // {
          # LSP extension (single file — all modules inlined)
          ".pi/agent/extensions/lsp/index.ts".source = ./pi/lsp/index.ts;
        };

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
                command = "${
                  inputs.nix-playwright-mcp.packages.${pkgs.stdenv.hostPlatform.system}.playwright-mcp-wrapper
                }/bin/playwright-mcp";
                args = [ ];
              };
              zellij = {
                command = "${pkgs.nixicle.zellij-mcp}/bin/zellij-mcp";
                args = [ ];
              };
              zellij-pane-tracker = {
                command = "${pkgs.nixicle.zellij-pane-tracker-plugin}/bin/zellij-pane-tracker-mcp";
                args = [ ];
              };
              postgres = {
                command = "uvx";
                args = [
                  "postgres-mcp"
                  "--access-mode=unrestricted"
                ];
              };
            };
          };

          opencode = {
            enable = true;

            commands.session-summary = "Summarize this session. First ask: personal or work? Based on answer, create notes at ~/projects/notes/notes/{work|personal}/YYYY-MM-DD-<topic>.md with summary. Update the weekly journal at ~/projects/notes/journals/weekly/ to link it with [[filename]]. Keep it concise, bullet points, focus on what shipped.";

            tui.theme = "stylix";

            settings = lib.mkForce {
              "$schema" = "https://opencode.ai/config.json";
              model = "anthropic/claude-sonnet-4-20250514";
              autoshare = false;
              autoupdate = false;
              permission = {
                read."${config.home.homeDirectory}/.config/opencode/get-shit-done/*" = "allow";
                external_directory."${config.home.homeDirectory}/.config/opencode/get-shit-done/*" = "allow";
              };
              provider = {
                llama-swap = {
                  id = "llama-swap";
                  name = "llama-swap (Local)";
                  models = {
                    "llama-swap/qwen3-coder-30b" = {
                      name = "llama-swap/qwen3-coder-30b";
                      attach = { };
                    };
                    "llama-swap/qwen3-coder-30b:think" = {
                      name = "llama-swap/qwen3-coder-30b:think";
                      attach = { };
                    };
                    "llama-swap/qwen25-coder-7b" = {
                      name = "llama-swap/qwen25-coder-7b";
                      attach = { };
                    };
                  };
                  options = {
                    baseURL = "http://localhost:5800/v1";
                    apiKey = "sk-no-key";
                  };
                };
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
                zellij-pane-tracker = {
                  type = "local";
                  command = [
                    "${pkgs.nixicle.zellij-pane-tracker-plugin}/bin/zellij-pane-tracker-mcp"
                  ];
                  enabled = true;
                };
                nixos = {
                  type = "local";
                  command = [ "${pkgs.mcp-nixos}/bin/mcp-nixos" ];
                  enabled = true;
                };
                postgres = {
                  type = "local";
                  command = [
                    "uvx"
                    "postgres-mcp"
                    "--access-mode=unrestricted"
                  ];
                  enabled = false;
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

            agents = builtins.listToAttrs (
              map (name: {
                name = lib.removeSuffix ".md" name;
                value = agentDir + "/${name}";
              }) agentNames
            );
          };
        };

        home.packages = with pkgs; [
          gsdPackage
          (pi-coding-agent.overrideAttrs (_old: {
            postFixup = ''
              wrapProgram $out/bin/pi \
                --prefix PATH : ${lib.makeBinPath [ ripgrep ]} \
                --set NPM_CONFIG_PREFIX "$HOME/.pi/npm" \
                --set npm_config_prefix "$HOME/.pi/npm"
            '';
          }))
        ];

        # Kagi API key — decrypted at runtime by sops-nix
        sops.secrets.kagi_api_key = {
          sopsFile = ../../../modules/secrets.yaml;
        };

        # Point the Kagi extension at the sops-decrypted secret file
        home.sessionVariables.KAGI_API_KEY_FILE = config.sops.secrets.kagi_api_key.path;

      };
  };
}
