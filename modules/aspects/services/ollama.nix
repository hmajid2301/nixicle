{ den, ... }:
{
  den.aspects.ollama = {
    nixos = { config, pkgs, lib, ... }: {
      services.ollama = {
        enable = true;
        package = pkgs.ollama;
        environmentVariables = {
          OLLAMA_NUM_PARALLEL = "32";
          OLLAMA_MAX_LOADED_MODELS = "8";
          OLLAMA_MAX_QUEUE = "1024";
          OLLAMA_VULKAN = "1";
          OLLAMA_FLASH_ATTENTION = "true";
          OLLAMA_KV_CACHE_TYPE = "q8_0";
          OLLAMA_CONTEXT_LENGTH = "64000";
        };
        host = "0.0.0.0";
        port = 11434;
      };

      environment.persistence."/persist".directories =
        lib.mkIf config.system.impermanence.enable [ "/var/lib/private/ollama" ];
    };
  };
}
