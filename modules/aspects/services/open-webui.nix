_: {
  den.aspects.open-webui = {
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
        ...
      }:
      {
        sops.secrets.open_webui_oauth = { };
        services.open-webui = {
          enable = true;
          host = "0.0.0.0";
          port = 8185;
          environmentFile = config.sops.secrets.open_webui_oauth.path;
          environment = {
            ANONYMIZED_TELEMETRY = "False";
            DO_NOT_TRACK = "True";
            SCARF_NO_ANALYTICS = "True";
            OLLAMA_BASE_URL = "http://127.0.0.1:11434";
            OAUTH_PROVIDER_NAME = "Pocket ID";
            OPENID_PROVIDER_URL = "https://${config.nixicle.domains.sso}/.well-known/openid-configuration";
            OPENID_REDIRECT_URI = "https://open-webui.${config.nixicle.domains.root}/oauth/oidc/callback";
            WEBUI_URL = "https://open-webui.${config.nixicle.domains.root}";
            ENABLE_OAUTH_SIGNUP = "true";
            ENABLE_LOGIN_FORM = "false";
            OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "true";
          };
        };

      };
  };
}
