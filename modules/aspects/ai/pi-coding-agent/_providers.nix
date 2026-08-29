_:
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
    ];
  };
}
