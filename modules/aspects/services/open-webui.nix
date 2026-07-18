{ ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  den.aspects.open-webui = {
    includes = [ ];
    persist.directories = [
      {
        directory = "/var/lib/private/open-webui";
        user = "open-webui";
        group = "open-webui";
        mode = "0750";
        defaultPerms.mode = "0700";
      }
    ];
    nixos =
      {
        config,
        secrets,
        lib,
        ...
      }:
      let
        secretPaths = lib.mergeAttrsList secrets;
      in
      {
        sops.secrets.open_webui_oauth = { };
        services.open-webui = {
          enable = true;
          host = "0.0.0.0";
          port = 8185;
          environmentFile = secretPaths.open_webui_oauth;
          environment = {
            ANONYMIZED_TELEMETRY = "False";
            DO_NOT_TRACK = "True";
            SCARF_NO_ANALYTICS = "True";
            OLLAMA_BASE_URL = "http://127.0.0.1:11434";
            OAUTH_PROVIDER_NAME = "Pocket ID";
            OPENID_PROVIDER_URL = "https://id.haseebmajid.dev/.well-known/openid-configuration";
            OPENID_REDIRECT_URI = "https://open-webui.haseebmajid.dev/oauth/oidc/callback";
            WEBUI_URL = "https://open-webui.haseebmajid.dev";
            ENABLE_OAUTH_SIGNUP = "true";
            ENABLE_LOGIN_FORM = "false";
            OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
          };
        };

        services.cloudflared.tunnels.${tunnelId}.ingress."open-webui.haseebmajid.dev" =
          "http://localhost:8185";

      };
  };
}
