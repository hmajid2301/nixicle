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
    sops.secrets.open_webui_oauth = {
      sopsFile = ../secrets.yaml;
    };

    services = {
      ollama = {
        enable = true;
        package = pkgs.ollama-rocm;
        environmentVariables = {
          OLLAMA_NUM_PARALLEL = "32";
          OLLAMA_MAX_LOADED_MODELS = "8";
          OLLAMA_GPU_OVERHEAD = "2048";
          OLLAMA_MAX_QUEUE = "1024";
        };
        host = "0.0.0.0";
        port = 11434;
      };

      open-webui = {
        enable = true;
        host = "0.0.0.0";
        port = 8185;
        environmentFile = config.sops.secrets.open_webui_oauth.path;
        environment = {
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
          OLLAMA_BASE_URL = "http://127.0.0.1:11434";

          OAUTH_PROVIDER_NAME = "authentik";
          OPENID_PROVIDER_URL = "https://authentik.haseebmajid.dev/application/o/ollama-web-ui/.well-known/openid-configuration";
          OPENID_REDIRECT_URI = "https://open-webui.haseebmajid.dev/oauth/oidc/callback";
          WEBUI_URL = "https://open-webui.haseebmajid.dev";

          ENABLE_OAUTH_SIGNUP = "true";
          ENABLE_LOGIN_FORM = "false";
          OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
        };
      };
      cloudflared.tunnels = mkIf config.services.nixicle.cloudflare.enable {
        ${config.services.nixicle.cloudflare.tunnelId}.ingress = {
          "open-webui.haseebmajid.dev" = "http://localhost:8185";
        };
      };
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          { directory = "/var/lib/private/ollama"; user = "ollama"; group = "ollama"; mode = "0750"; defaultPerms.mode = "0700"; }
          { directory = "/var/lib/private/open-webui"; user = "open-webui"; group = "open-webui"; mode = "0750"; defaultPerms.mode = "0700"; }
        ];
      };
    };
  };
}
