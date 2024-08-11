{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.ollama;
in {
  options.services.nixicle.ollama = {
    enable = mkEnableOption "Enable ollama and web ui";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
    };

    services.open-webui = {
      enable = true;
      port = 8085;
    };
  };
}
