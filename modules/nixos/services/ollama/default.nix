{
  config,
  lib,
  pkgs,
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
      package = pkgs.ollama-rocm;  # AMD GPU package
      rocmOverrideGfx = "11.0.0";  # RX 7900 XTX (RDNA 3) support
    };

    services.open-webui = {
      enable = true;
      port = 8185;
      environment = {
        WEBUI_AUTH = "False";
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
      };
    };
  };
}
