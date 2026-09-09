{ inputs, ... }:
{
  flake-file.inputs.nixflix = {
    url = "github:kiriwalawren/nixflix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Jellyfin-only aspect (no arr stack). Reuses the nixflix module but enables
  # only `nixflix.jellyfin`; every other service defaults to `false`.
  #
  # Host-specific bits (mediaDir, encoding) are overridable by the host.
  den.aspects.jellyfin = {
    nixos =
      {
        lib,
        secrets,
        ...
      }:
      let
        secretPaths = lib.mergeAttrsList secrets;
      in
      {
        imports = [ inputs.nixflix.nixosModules.nixflix ];

        sops.secrets = {
          "jellyfin/admin_password" = { };
          "jellyfin/api_key" = { };
          "jellyfin/client_id" = { };
          "jellyfin/client_secret" = { };
        };

        nixflix = {
          enable = true;
          mediaDir = "/mnt/main/main-encrypted/homelab/media";
          stateDir = "/persist/nixflix";
          downloadsDir = "/persist/nixflix/downloads";
          mediaUsers = [ "haseeb" ];

          globals.gids.media = 3000;

          jellyfin = {
            enable = true;
            apiKey._secret = secretPaths."jellyfin/api_key";

            encoding = {
              hardwareAccelerationType = "vaapi";
              vaapiDevice = "/dev/dri/renderD128";
              enableHardwareEncoding = true;
            };

            system.pluginRepositories = {
              "SSO-Auth" = {
                url = "https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json";
                hash = "sha256-lX45HueVfT/xfIxkYn5eQobmVXBoi5jdpJCx43edRA0=";
              };
            };

            plugins."SSO Authentication" = {
              enable = true;
              apiName = "SSO-Auth";
              package = inputs.nixflix.lib.jellyfinPlugins.fromRepo {
                version = "4.0.0.4";
                hash = "sha256-MJTyE6CeVLk7mlugauJ/F6bpi1kYwNtzNmQeH3+CFeQ=";
                repository = "SSO-Auth";
              };
              config = {
                OidConfigs = {
                  pocketid = {
                    Enabled = true;
                    EnableAuthorization = true;
                    EnableAllFolders = true;
                    OidEndpoint = "https://id.haseebmajid.dev/.well-known/openid-configuration";
                    OidClientId._secret = secretPaths."jellyfin/client_id";
                    OidSecret._secret = secretPaths."jellyfin/client_secret";
                    OidScopes = [
                      "openid"
                      "profile"
                      "email"
                      "offline"
                      "groups"
                    ];
                    RoleClaim = "groups";
                    Roles = [ "family" ];
                    AdminRoles = [ "jellyfin_admins" ];
                    SchemeOverride = "https";
                  };
                };
              };
            };

            branding = {
              loginDisclaimer = ''
                <form action="https://jellyfin.haseebmajid.dev/sso/OID/p/pocketid">
                  <button class="raised block emby-button button-submit">
                    Sign in with SSO
                  </button>
                </form>
              '';
              customCss = ''
                a.raised.emby-button {
                    padding:0.9em 1em;
                    color: inherit !important;
                }
                .disclaimerContainer{
                    display: block;
                }
              '';
            };

            users.admin = {
              mutable = false;
              policy.isAdministrator = true;
              password._secret = secretPaths."jellyfin/admin_password";
            };
          };
        };

        hardware.graphics.enable = true;
        boot.kernelModules = [ "i915" ];
      };
  };
}
