_: {
  den.aspects.atuinAi = {
    nixos =
      { config, ... }:
      {
        sops.secrets.atuin_ai_auth_token = { };

        environment.etc."atuin-ai/config.toml" = {
          mode = "0440";
          text = ''
            port = 8080
            endpoint = "http://127.0.0.1:11434/v1"
            default_model = "qwen2.5-coder-7b"

            [request.body]
            stream_options = { include_usage = true }

            [[models]]
            alias = "qwen2.5-coder-7b"
            name = "Qwen 2.5 Coder 7B"
            description = "Local qwen2.5-coder via Ollama"
            model = "qwen2.5-coder:7b"
          '';
        };

        virtualisation.oci-containers = {
          backend = "docker";
          containers.atuin-ai = {
            image = "ghcr.io/atuinsh/atuin-ai-server:latest";
            autoStart = true;
            extraOptions = [
              "--network"
              "host"
            ];
            environmentFiles = [ config.sops.secrets.atuin_ai_auth_token.path ];
            volumes = [
              "/etc/atuin-ai/config.toml:/etc/atuin-ai/config.toml:ro"
            ];
          };
        };
      };
  };
}
