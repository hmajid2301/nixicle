_: {
  den.aspects.pi-coding-agent = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        ketchModule = import ./_ketch.nix { inherit config lib; };
        themeModule = import ./_theme.nix { inherit config pkgs; };
        aiCfg = config.nixicle.ai;
        piExtensionFiles = import ./_extensions.nix { };
        baseProviders = import ./_providers.nix { };
        piInputType = lib.types.enum [
          "text"
          "image"
        ];
        piModelType = lib.types.submodule {
          options = {
            id = lib.mkOption {
              type = lib.types.str;
              example = "qwen3.6:27b";
              description = "Provider model identifier exposed to Pi.";
            };
            input = lib.mkOption {
              type = lib.types.nonEmptyListOf piInputType;
              example = [
                "text"
                "image"
              ];
              description = "Input modalities supported by this model.";
            };
          };
        };
        dedupeModels =
          models:
          (lib.foldr
            (
              model: acc:
              if builtins.hasAttr model.id acc.seen then
                acc
              else
                {
                  seen = acc.seen // {
                    "${model.id}" = true;
                  };
                  ordered = [ model ] ++ acc.ordered;
                }
            )
            {
              seen = { };
              ordered = [ ];
            }
            models
          ).ordered;
        mergedProviders = lib.mapAttrs (
          name: provider:
          provider
          // {
            models = dedupeModels (provider.models ++ (aiCfg.extraPiModels.${name} or [ ]));
          }
        ) baseProviders;
        cloudOllamaProviders = lib.optionalAttrs (aiCfg.ollamaCloudModels != [ ]) {
          ollama-cloud = baseProviders.ollama // {
            models = dedupeModels aiCfg.ollamaCloudModels;
          };
        };
      in
      {
        options = lib.recursiveUpdate ketchModule.options {
          nixicle.ai = {
            extraPiModels = lib.mkOption {
              type = lib.types.attrsOf (lib.types.listOf piModelType);
              default = { };
              description = ''
                Extra Pi agent provider models keyed by provider name (e.g. `ollama`, `llama-swap`).
                Use this to add models and declare supported input modalities.
                Example: `ollama = [ { id = "qwen3.6:27b"; input = [ "text" "image" ]; } ];`
              '';
            };

            ollamaCloudModels = lib.mkOption {
              type = lib.types.listOf piModelType;
              default = [ ];
              description = ''
                Optional cloud-routed models exposed through local Ollama endpoint.
                Kept separate from built-in local Ollama models so hosts without those aliases stay stable.
                When non-empty, Pi gets an additional `ollama-cloud` provider.
              '';
            };
          };
        };

        config = lib.mkMerge [
          ketchModule.config
          themeModule.config
          {
            home.file = {
              ".pi/agent/agents" = {
                source = ../agents;
                recursive = true;
              };
            }
            // builtins.listToAttrs (
              map (ext: {
                name = ".pi/agent/extensions/${ext.rel}";
                value.source = ext.src;
              }) piExtensionFiles
            );

            programs.pi-coding-agent = {
              enable = true;
              settings = {
                defaultProvider = "openai-codex";
                defaultModel = "gpt-5.4";
                defaultThinkingLevel = "medium";
                theme = "stylix";
                packages = [ ];
                extensions = map (ext: "~/.pi/agent/extensions/${ext.rel}") piExtensionFiles;
              };
              models.providers = mergedProviders // cloudOllamaProviders;
            };

            home.packages = with pkgs; [
              gh
              glab
              ddgr
              ketch
              codegraph
            ];
          }
        ];
      };
  };
}
