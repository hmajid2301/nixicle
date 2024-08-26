# home lab docs

## tandoor

no social logisn firs time setup then enable

          SOCIAL_DEFAULT_GROUP = "user";
          SOCIAL_PROVIDERS = "allauth.socialaccount.providers.openid_connect";

## Tandoor auth


set  SOCIALACCOUNT_PROVIDERS

```json
{ "openid_connect": { "SERVERS": [ { "id": "tandoor", "name": "authentik", "server_url": "https://auth.bare.homelab.haseebmajid.dev/application/o/tandoor/.well-known/openid-configuration", "token_auth_method": "client_secret_basic", "APP": { "client_id": "", "secret": "", }, } ] }}
```

Ref: https://github.com/TandoorRecipes/recipes/issues/970
allow us to include the env data in systemd

    systemd.services.paperless-web = {
      serviceConfig = {
        EnvironmentFile = [config.sops.secrets.paperless.path];
      };
      after = ["postgresql.service"];
    };

don't set redirect allow it to be set first time request is made.

### Tandoor Photos

```
Hi, I’ve been bitten by the same issue. I was able to pinpoint the issue by looking into nginx logs:

journalctl -u nginx.service

I was able to find the following line:

Apr 23 13:23:48 odroid nginx[577544]: 2024/04/23 13:23:48 [error] 577544#577544: *3442 open() "/var/lib/tandoor-recipes/recipes/91463ea6-4fad-4b90-b9e1-67230ebd20d7_18.jpg" failed (13: Permission denied), client: 192.168.0.128, server: tandoor.house.flakm.com, request: "GET /media/recipes/91463ea6-4fad-4b90-b9e1-67230ebd20d7_18.jpg HTTP/2.0", host: "tandoor.house.flakm.com", referrer: "https://tandoor.house.flakm.com/search/"

The line might be different for you, but it shows that Nginx does not have permission to file files in the expected location. You can check this by issuing:

sudo su - nginx -s $(which bash)
# and now you can test:
[nginx@odroid:~]$ cd /var/lib/tandoor-recipes/                                
-bash: cd: /var/lib/tandoor-recipes/: Permission denied 
[nginx@odroid:~]$ cd /var/lib/private/                                
-bash: cd: /var/lib/private/: Permission denied 

Systemd configuration for the service 1 uses DynamicUser as you can see here: systemd.exec 1

So, to fix this, I had to add nginx into relevant groups:

  users.groups.tandoor-recipes.members = [ "nginx" ];

Add nginx alias for media in locations:

          "/media/".alias = "/var/lib/tandoor-recipes/";

And issue the following commands:

# allow users to enter into this directory
sudo chmod o+x /var/lib/private/tandoor-recipes
sudo chmod o+x /var/lib/private/

You can read all the configuration here: tandoor.nix 6

I’m adding +x so the nginx user can enter the directory owned by the root:root.

Having execute permission on a directory authorizes you to look at extended information on files in the directory (using ls -l, for instance) but also allows you to change your working directory (using cd) or pass through this directory on your way to a subdirectory underneath.

And nginx to group tandoor-receipes so it can read the files owned by the tandoor’s dynamic user.
```

https://github.com/FlakM/nix_dots/blob/main/hosts/odroid/tandoor.nix

      services.nginx = {
        enable = true;
        virtualHosts = {
          "recipes-media" = {
            listen = [
              {
                addr = "localhost";
                port = 8100;
              }
            ];
            locations = {
              "/media/" = {
                alias = "/var/lib/tandoor-recipes/";
              };
            };
          };
        };
      };


      traefik = {
        dynamicConfigOptions = {
          http = {
            services = {
              recipes-media.loadBalancer.servers = [
                {
                  url = "http://localhost:8100";
                }
              ];
              recipes.loadBalancer.servers = [
                {
                  url = "http://localhost:8099";
                }
              ];
            };

            routers = {
              recipes = {
                entryPoints = ["websecure"];
                rule = "Host(`recipes.bare.homelab.haseebmajid.dev`)";
                service = "recipes";
                tls.certResolver = "letsencrypt";
              };

              recipes-media = {
                entryPoints = ["websecure"];
                rule = "Host(`recipes.bare.homelab.haseebmajid.dev`) && PathPrefix(`/media`)";
                service = "recipes-media";
                tls.certResolver = "letsencrypt";
              };
            };
          };
        };





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

## NixOS



```bash
sudo -u postgres psql

psql (14.13)
Type "help" for help.

postgres-# \l
                                        List of databases
      Name       |      Owner      | Encoding |   Collate   |    Ctype    |   Access privileges
-----------------+-----------------+----------+-------------+-------------+-----------------------
 authentik       | authentik       | UTF8     | en_GB.UTF-8 | en_GB.UTF-8 |
 postgres        | postgres        | UTF8     | en_GB.UTF-8 | en_GB.UTF-8 |
 tandoor         | tandoor         | UTF8     | en_GB.UTF-8 | en_GB.UTF-8 |
 template0       | postgres        | UTF8     | en_GB.UTF-8 | en_GB.UTF-8 | =c/postgres          +
                 |                 |          |             |             | postgres=CTc/postgres
 template1       | postgres        | UTF8     | en_GB.UTF-8 | en_GB.UTF-8 | =c/postgres          +
                 |                 |          |             |             | postgres=CTc/postgres
postgres=# dropdb "tandoor";
postgres=# \l
                                  List of databases
   Name    |   Owner   | Encoding |   Collate   |    Ctype    |   Access privileges
-----------+-----------+----------+-------------+-------------+-----------------------
 authentik | authentik | UTF8     | en_GB.UTF-8 | en_GB.UTF-8 |
 postgres  | postgres  | UTF8     | en_GB.UTF-8 | en_GB.UTF-8 |
 template0 | postgres  | UTF8     | en_GB.UTF-8 | en_GB.UTF-8 | =c/postgres          +
           |           |          |             |             | postgres=CTc/postgres
 template1 | postgres  | UTF8     | en_GB.UTF-8 | en_GB.UTF-8 | =c/postgres          +
           |           |          |             |             | postgres=CTc/postgres
```

### Cloudflare


The configuration you provided expects a credentials file that is usually generated after you run the cloudflared tunnel create command. However, since you only have a token, you can still configure the tunnel by following these steps:
Steps to Use a Token Instead of a Credentials File:

    Install Cloudflared (if not already installed): Ensure that cloudflared is installed on your system. If not, you can install it using the following command:

    bash nix-env -iA nixpkgs.cloudflared

    Authenticate Using the Token: Use the provided token to authenticate and create the credentials file. Run the following command in your terminal:

    bash cloudflared tunnel login

    This command will prompt you to open a browser and log in to your Cloudflare account. Once logged in, Cloudflare will generate a certificate and place it in ~/.cloudflared/cert.pem.

    Create a New Tunnel Using the Token: Now, use the token to create a new tunnel and automatically generate the required credentials file:

    bash cloudflared tunnel create your-tunnel-name

    This command will generate a credentials file, usually located at ~/.cloudflared/your-tunnel-name.json.

    Update Your NixOS Configuration: Once the credentials file is generated, you can reference it in your NixOS configuration like this:

    ```nix { config, pkgs, ... }:

    { services.cloudflared = { enable = true; tunnels = { “your-tunnel-name” = { default = “http_status:404”; ingress = { “your-domain.com” = “http://localhost:8000”; }; credentialsFile = “/var/lib/cloudflared/your-tunnel-name.json”; }; }; }; } ```

    Make sure to copy the generated credentials file to /var/lib/cloudflared/your-tunnel-name.json or update the path in the configuration to where the file is located.

    Restart Cloudflared Service: Finally, apply the NixOS configuration and restart the cloudflared service:

    bash sudo nixos-rebuild switch sudo systemctl restart cloudflared

This should set up the Cloudflare tunnel correctly using the token and credentials file.

 
On top of all of that, you will want to add a CNAME entry to your domain:

cloudflared tunnel route dns <tunnel name/id> <hostname>

This is how I like my ./tunnels.nix:

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pkgs.unstable.cloudflared
  ];

  services.cloudflared = {
    enable = true;
    user = "my-user";
    package = pkgs.unstable.cloudflared;
    tunnels = {
      "xxxx-xxxx-xxxx" = {
        credentialsFile = "${config.users.users.my-user.home}/.cloudflared/xxxx-xxxx-xxxx.json";
        default = "http_status:404";
        ingress = {
          "*.example.com" = {
            service = "http://localhost:8080";
          };
        };
      };
    };
  };

}

key being owner is cloudflared

    sops.secrets.cloudflared = {
      sopsFile = ../secrets.yaml;
      owner = "cloudflared";
    };

That error message indicates that hostname is too deep to be covered by Universal SSL. See the following chart for details.
Hostname 	Covered by Universal certificate?
example.com 	Yes
www.example.com 	Yes
docs.example.com 	Yes
dev.docs.example.com 	No
test.dev.api.example.com 	No

hostname needs to be like tandoor-recipes.haseebmajid.dev

![tls-cloudflare-issue.png](assets/imgs/tls-cloudflare-issue.png)

Multi domain authentik: https://www.youtube.com/watch?v=tqimi3SdvCQ

![tunnel-order.png](assets/imgs/tunnel-order.png)
