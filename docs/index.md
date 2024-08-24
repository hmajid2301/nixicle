# home lab docs

## Tandoor auth

redirect uri: https://recipes.bare.homelab.haseebmajid.dev/accounts/oidc/tandoor/login/callback/

set  SOCIALACCOUNT_PROVIDERS

```json
{ "openid_connect": { "SERVERS": [ { "id": "tandoor", "name": "authentik", "server_url": "https://auth.bare.homelab.haseebmajid.dev/application/o/tandoor/.well-known/openid-configuration", "token_auth_method": "client_secret_basic", "APP": { "client_id": "", "secret": "", }, } ] }}
```

Ref: https://github.com/TandoorRecipes/recipes/issues/970

## Audible

Get activation from here https://audible-tools.kamsker.at/

```bash
ffmpeg -activation_bytes XXXX -i audiobook.aax audiobook.mp3
```

https://kylepiira.com/2019/05/12/how-to-break-audible-drm/

## Traefik authentik forward auth

![forward-auth-sonarr.png](assets/imgs/forward-auth-sonarr.png)
![http-basic-auth.png](assets/imgs/http-basic-auth.png)
![update-outpost.png](assets/imgs/update-outpost.png)

The key here being the outpost needs to use https and 9443

```nix

      traefik = {
        dynamicConfigOptions = {
          http = {
            middlewares = {
              authentik = {
                forwardAuth = {
                  tls.insecureSkipVerify = true;
                  address = "https://localhost:9443/outpost.goauthentik.io/auth/traefik";
                  trustForwardHeader = true;
                  authResponseHeaders = [
                    "X-authentik-username"
                    "X-authentik-groups"
                    "X-authentik-email"
                    "X-authentik-name"
                    "X-authentik-uid"
                    "X-authentik-jwt"
                    "X-authentik-meta-jwks"
                    "X-authentik-meta-outpost"
                    "X-authentik-meta-provider"
                    "X-authentik-meta-app"
                    "X-authentik-meta-version"
                  ];
                };
              };
            };

            services = {
              auth.loadBalancer.servers = [
                {
                  url = "http://localhost:9000";
                }
              ];
            };

            routers = {
              auth = {
                entryPoints = ["websecure"];
                rule = "Host(`auth.bare.homelab.haseebmajid.dev`) || HostRegexp(`{subdomain:[a-z0-9]+}.bare.homelab.haseebmajid.com`) && PathPrefix(`/outpost.goauthentik.io/`)";
                service = "auth";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };
      };
```



set middleware on sonarr

````nix
  sonarr = {
    entryPoints = ["websecure"];
    rule = "Host(`sonarr.bare.homelab.haseebmajid.dev`)";
    service = "sonarr";
    tls.certResolver = "letsencrypt";
    middlewares = ["authentik"];
  };
````

## HA

````nix

{
  lib,
  pkgs,
  fetchFromGitHub,
  buildHomeAssistantComponent,
}:
buildHomeAssistantComponent rec {
  owner = "graham33";
  domain = "octopus-energy";
  version = "12.2.0";
  format = "other";

  src = fetchFromGitHub {
    owner = "BottlecapDave";
    repo = "HomeAssistant-OctopusEnergy";
    rev = "v${version}";
    sha256 = "sha256-qBvr+7oMAhTyxlWSo+CPddZ00aIGt+0s3x/LlEKUrN4=";
  };

  checkInputs = with pkgs.python312Packages;
  with pkgs; [
    home-assistant
    mock
    psutil-home-assistant
    pytest
    pytest-socket
    pytest-asyncio
    sqlalchemy
  ];

  checkPhase = ''
    python -m pytest tests/unit
  '';

  meta = with lib; {
    homepage = "https://github.com/BottlecapDave/HomeAssistant-OctopusEnergy";
    license = licenses.mit;
    description = "Custom component to bring your Octopus Energy details into Home Assistant";
    maintainers = with maintainers; [graham33];
  };
}
````
