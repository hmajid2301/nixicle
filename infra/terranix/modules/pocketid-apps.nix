let
  apps = {
    goroutinely = {
      name = "Goroutinely";
      client_id = "goroutinely";
      launch_url = "https://goroutinely.haseebmajid.dev";
      callback_urls = [
        "https://goroutinely.haseebmajid.dev/callback"
      ];
      is_public = false;
      pkce_enabled = true;
    };

    lettucego = {
      name = "LettuceGo";
      client_id = "lettucego";
      launch_url = "https://lettucego.haseebmajid.dev";
      callback_urls = [
        "https://lettucego.haseebmajid.dev/callback"
      ];
      # PKCE enabled. lettucego uses a manual OAuth2 impl that now supports it
      # via code_challenge=S256 + code_verifier stored in cookie.
      # See internal/transport/http/handlers/auth.go generateCodeVerifier + sha256Hash.
      is_public = false;
      pkce_enabled = true;
    };

    karakeep = {
      name = "KaraKeep";
      client_id = "karakeep";
      launch_url = "https://karakeep.haseebmajid.dev";
      callback_urls = [
        "https://karakeep.haseebmajid.dev/api/auth/callback/custom"
      ];
      is_public = false;
      pkce_enabled = true;
    };

    papra = {
      name = "Papra";
      client_id = "papra";
      launch_url = "https://papra.haseebmajid.dev";
      callback_urls = [
        "https://papra.haseebmajid.dev/api/auth/oauth2/callback/pocketid"
      ];
      is_public = false;
      pkce_enabled = true;
    };

    tandoor = {
      name = "Tandoor";
      client_id = "tandoor";
      launch_url = "https://tandoor-recipes.haseebmajid.dev";
      callback_urls = [
        "https://tandoor-recipes.haseebmajid.dev/accounts/oidc/pocket-id/login/callback/"
      ];
      is_public = false;
      pkce_enabled = false;
    };
  };

  mkClient = key: cfg: {
    resource.pocketid_client.${key} = {
      inherit (cfg)
        name
        client_id
        callback_urls
        is_public
        pkce_enabled
        launch_url
        ;
    };

    output."${key}_client_id" = {
      value = "\${pocketid_client.${key}.id}";
    };

    output."${key}_client_secret" = {
      value = "\${pocketid_client.${key}.client_secret}";
      sensitive = true;
    };
  };
in
{
  imports = builtins.attrValues (builtins.mapAttrs mkClient apps);
}
