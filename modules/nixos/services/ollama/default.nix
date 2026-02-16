{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.ollama;
in
{
  options.services.nixicle.ollama = {
    enable = mkEnableOption "Enable ollama and web ui";

    acceleration = mkOption {
      type = types.enum [ "rocm" "cuda" "vulkan" "cpu" ];
      default = "cpu";
      description = "GPU acceleration backend to use (rocm for AMD, cuda for NVIDIA, vulkan for Vulkan API, cpu for no acceleration)";
    };

    vulkan = {
      flashAttention = mkOption {
        type = types.bool;
        default = true;
        description = "Enable flash attention optimization";
      };
      kvCacheType = mkOption {
        type = types.str;
        default = "q8_0";
        description = "KV cache quantization type";
      };
      contextLength = mkOption {
        type = types.int;
        default = 64000;
        description = "Context length for model";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install ROCm support for AMD GPUs if using rocm acceleration
    hardware.graphics = mkIf (cfg.acceleration == "rocm") {
      enable = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
      ];
    };

    services.ollama = {
      enable = true;
      # Use the appropriate ollama package variant based on acceleration type
      package =
        if cfg.acceleration == "rocm" then pkgs.ollama-rocm
        else if cfg.acceleration == "cuda" then pkgs.ollama-cuda
        else if cfg.acceleration == "vulkan" then pkgs.ollama
        else pkgs.ollama;

      environmentVariables = mkMerge [
        {
          OLLAMA_NUM_PARALLEL = "32";
          OLLAMA_MAX_LOADED_MODELS = "8";
          OLLAMA_MAX_QUEUE = "1024";
        }
        (mkIf (cfg.acceleration == "vulkan") {
          OLLAMA_VULKAN = "1";
          OLLAMA_FLASH_ATTENTION = if cfg.vulkan.flashAttention then "true" else "false";
          OLLAMA_KV_CACHE_TYPE = cfg.vulkan.kvCacheType;
          OLLAMA_CONTEXT_LENGTH = toString cfg.vulkan.contextLength;
        })
      ];
      host = "0.0.0.0";
      port = 11434;
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        "/var/lib/private/ollama"
      ];
    };
  };
}
