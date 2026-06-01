{ ... }:
{
  den.aspects.llama-cpp = {
    includes = [ ];
    persist.directories = [ "/var/lib/private/llama-cpp" ];
    nixos =
      {
        pkgs,
        lib,
        ...
      }:
      let
        llamaCpp = pkgs.llama-cpp.override { vulkanSupport = true; };
        llamaServer = "${llamaCpp}/bin/llama-server";
        qwen3vl8b = pkgs.fetchurl {
          url = "https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF/resolve/main/Qwen3VL-8B-Instruct-Q4_K_M.gguf";
          hash = "sha256-Z9Flm/5xuJ1QtFpK0anluZfluxbOXaZqamFnq9Vp6eI=";
        };
        qwen3vl8bMmproj = pkgs.fetchurl {
          url = "https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF/resolve/main/mmproj-Qwen3VL-8B-Instruct-Q8_0.gguf";
          hash = "sha256-xrqFUI2C9CWQ5ut31TQDaatv7PEHp1YdgJUj2KpfO/0=";
        };
      in
      {
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };

        environment.systemPackages = [ llamaCpp ];

        services.llama-swap = {
          enable = true;
          package = pkgs.llama-swap;
          listenAddress = "0.0.0.0";
          port = 5800;
          openFirewall = true;
          # environment = {
          #   HF_TOKEN = pkgs.lib.getEnv "HF_TOKEN" || "";
          # };
          settings = {
            healthCheckTimeout = 300;
            models = {
              "qwen3-coder-30b" = {
                cmd = "${llamaServer} --host 0.0.0.0 --port \${PORT} --n-gpu-layers 99 -hf ggml-org/Qwen3-Coder-30B-A3B-GGUF:Q4_K_M --ctx-size 32768 --threads 8";
              };
              "qwen3-coder-30b:think" = {
                cmd = "${llamaServer} --host 0.0.0.0 --port \${PORT} --n-gpu-layers 99 -hf ggml-org/Qwen3-Coder-30B-A3B-GGUF:Q4_K_M --ctx-size 32768 --threads 8 --reasoning-effort high";
              };
              "qwen25-coder-7b" = {
                cmd = "${llamaServer} --host 0.0.0.0 --port \${PORT} --n-gpu-layers 99 -hf ggml-org/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M --ctx-size 32768 --threads 8";
              };
              "qwen3-vl:8b" = {
                cmd = "${llamaServer} --host 0.0.0.0 --port \${PORT} --n-gpu-layers 99 -m ${qwen3vl8b} --mmproj ${qwen3vl8bMmproj} --ctx-size 16384 --threads 8";
              };
            };
          };
        };

        services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "llama-swap";
          port = 5800;
          subdomain = "llama";
        };

      };
  };
}
