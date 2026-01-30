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
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama;
      environmentVariables = {
        OLLAMA_NUM_PARALLEL = "32";
        OLLAMA_MAX_LOADED_MODELS = "8";
        OLLAMA_MAX_QUEUE = "1024";
      };
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
