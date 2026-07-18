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
      rel = "codegraph.ts";
      src = ./pi/codegraph.ts;
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
  den.aspects.ai = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.nixicle.ketch;
        configuredKetchSecrets =
          if cfg.enable then
            lib.filterAttrs (_: value: value != null) {
              brave_api_key = cfg.secrets.braveApiKey;
              exa_api_key = cfg.secrets.exaApiKey;
              context7_api_key = cfg.secrets.context7ApiKey;
              github_token = cfg.secrets.githubToken;
            }
          else
            { };
        declaredKetchSecrets = builtins.listToAttrs (
          map (secretName: {
            name = secretName;
            value = { };
          }) (lib.unique (builtins.attrValues configuredKetchSecrets))
        );
        ketchSecretPlaceholders = lib.mapAttrs' (
          jsonKey: secretName: lib.nameValuePair jsonKey config.sops.placeholder.${secretName}
        ) configuredKetchSecrets;
        ketchConfig = {
          backend = cfg.settings.backend;
          searxng_url = cfg.settings.searxngUrl;
          limit = cfg.settings.limit;
          cache_ttl = cfg.settings.cacheTTL;
          code_backend = cfg.settings.codeBackend;
          docs_backend = cfg.settings.docsBackend;
          sourcegraph_url = cfg.settings.sourcegraphURL;
        }
        // lib.optionalAttrs (cfg.settings.browser != null) {
          browser = cfg.settings.browser;
        }
        // lib.optionalAttrs (cfg.settings.urlRewrites != [ ]) {
          url_rewrites = cfg.settings.urlRewrites;
        }
        // lib.optionalAttrs (cfg.settings.spaMarkers != [ ]) {
          spa_markers = cfg.settings.spaMarkers;
        }
        // ketchSecretPlaceholders;
      in
      {
        options.nixicle.ketch = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to manage ketch config.json with Home Manager.";
          };

          settings = lib.mkOption {
            description = "Non-secret ketch config values.";
            default = { };
            type = lib.types.submodule {
              options = {
                backend = lib.mkOption {
                  type = lib.types.enum [
                    "brave"
                    "ddg"
                    "searxng"
                    "exa"
                  ];
                  default = "searxng";
                };
                searxngUrl = lib.mkOption {
                  type = lib.types.str;
                  default = "http://127.0.0.1:8082";
                };
                limit = lib.mkOption {
                  type = lib.types.ints.positive;
                  default = 5;
                };
                cacheTTL = lib.mkOption {
                  type = lib.types.str;
                  default = "72h";
                };
                browser = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                codeBackend = lib.mkOption {
                  type = lib.types.enum [
                    "grepapp"
                    "sourcegraph"
                    "github"
                  ];
                  default = "grepapp";
                };
                docsBackend = lib.mkOption {
                  type = lib.types.enum [
                    "context7"
                    "local"
                  ];
                  default = "context7";
                };
                sourcegraphURL = lib.mkOption {
                  type = lib.types.str;
                  default = "https://sourcegraph.com";
                };
                urlRewrites = lib.mkOption {
                  default = [ ];
                  type = lib.types.listOf (
                    lib.types.submodule {
                      options = {
                        match = lib.mkOption { type = lib.types.str; };
                        replace = lib.mkOption { type = lib.types.str; };
                      };
                    }
                  );
                };
                spaMarkers = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
              };
            };
          };

          secrets = lib.mkOption {
            description = "SOPS secret names to inject into ketch config.json.";
            default = { };
            type = lib.types.submodule {
              options = {
                braveApiKey = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                exaApiKey = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                context7ApiKey = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
                githubToken = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                };
              };
            };
          };
        };

        config = {
          sops.secrets = lib.mkIf cfg.enable declaredKetchSecrets;
          sops.templates."ketch-config.json" = lib.mkIf cfg.enable {
            content = builtins.toJSON ketchConfig;
            path = "${config.xdg.configHome}/ketch/config.json";
            mode = "0600";
          };

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
            ketch
            codegraph
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
  };
}
