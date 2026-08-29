{
  config,
  lib,
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
      value = {
        sopsFile = lib.nixicle.secretsFile;
      };
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
  };
}
