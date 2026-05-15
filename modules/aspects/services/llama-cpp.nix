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
      {
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };

        environment.systemPackages = [
          (pkgs.llama-cpp.override { vulkanSupport = true; })
        ];

        services.llama-swap = {
          enable = true;
          package = pkgs.llama-swap;
          listenAddress = "0.0.0.0";
          port = 5800;
          openFirewall = true;
          settings = {
            healthCheckTimeout = 300;
            models = {
              "qwen3-coder-30b" = {
                cmd =
                  let
                    llama-server = "${pkgs.llama-cpp.override { vulkanSupport = true; }}/bin/llama-server";
                  in
                  "${llama-server} --host 0.0.0.0 --port \${PORT} --n-gpu-layers 99 -hf ggml-org/Qwen3-Coder-30B-A3B-GGUF:Q4_K_M --ctx-size 32768 --threads 8";
              };
              "qwen3-coder-30b:think" = {
                cmd =
                  let
                    llama-server = "${pkgs.llama-cpp.override { vulkanSupport = true; }}/bin/llama-server";
                  in
                  "${llama-server} --host 0.0.0.0 --port \${PORT} --n-gpu-layers 99 -hf ggml-org/Qwen3-Coder-30B-A3B-GGUF:Q4_K_M --ctx-size 32768 --threads 8 --reasoning-effort high";
              };
              "qwen25-coder-7b" = {
                cmd =
                  let
                    llama-server = "${pkgs.llama-cpp.override { vulkanSupport = true; }}/bin/llama-server";
                  in
                  "${llama-server} --host 0.0.0.0 --port \${PORT} --n-gpu-layers 99 -hf ggml-org/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M --ctx-size 32768 --threads 8";
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
