{
  config,
  ...
}:
let
  mkModel = id: input: { inherit id input; };
  mkTextModel = id: mkModel id [ "text" ];
  mkVisionModel =
    id:
    mkModel id [
      "text"
      "image"
    ];
in
{
  llama-swap = {
    baseUrl = "http://localhost:5800/v1";
    api = "openai-completions";
    apiKey = "sk-no-key";
    models = [
      (mkTextModel "qwen3-coder-30b")
      (mkTextModel "qwen3-coder-30b:think")
      (mkTextModel "qwen25-coder-7b")
      (mkVisionModel "qwen3-vl:8b")
    ];
  };
  ollama = {
    baseUrl = "http://localhost:11434/v1";
    api = "openai-completions";
    apiKey = "ollama";
    models = [
      (mkVisionModel "qwen3.6:27b")
      (mkTextModel "deepseek-v4-pro:cloud")
      (mkTextModel "deepseek-v4-flash:cloud")
      (mkVisionModel "kimi-k2.7-code:cloud")
      (mkVisionModel "kimi-k2.6:cloud")
      (mkTextModel "glm-5.3:cloud")
      (mkVisionModel "glm-5.3-flash:cloud")
      (mkTextModel "glm-5.2:cloud")
      (mkVisionModel "gemma4:cloud")
      (mkVisionModel "minimax-m3:cloud")
      (mkTextModel "minimax-m2.7:cloud")
    ];
  };
  solheim = {
    baseUrl = "https://api.solheim.ai/v1";
    api = "openai-completions";
    apiKey = "!cat ${config.sops.secrets.solheim_api_key.path}";
    models = [
      (mkTextModel "qwen3.8-27b")
    ];
  };
}
