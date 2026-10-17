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
        config,
        pkgs,
        ...
      }:
      let
        ssoManifest = "${inputs.jellyfin-sso}/manifest.json";
        ssoRev = inputs.jellyfin-sso.rev;
        ssoManifestHash = builtins.convertHash {
          hash = builtins.hashFile "sha256" ssoManifest;
          hashAlgo = "sha256";
          toHashFormat = "nix32";
        };
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
          theme = {
            enable = true;
            name = "catppuccin-macchiato";
          };
          mediaDir = "/mnt/main/main-encrypted/homelab/media";
          stateDir = "/persist/nixflix";
          downloadsDir = "/persist/nixflix/downloads";
          mediaUsers = [ "haseeb" ];

          globals.gids.media = 3000;

          jellyfin = {
            enable = true;
            apiKey._secret = config.sops.secrets."jellyfin/api_key".path;

            encoding = {
              hardwareAccelerationType = "vaapi";
              vaapiDevice = "/dev/dri/renderD128";
              enableHardwareEncoding = true;
            };

            system.trickplayOptions = {
              enableHwAcceleration = true;
              enableHwEncoding = true;
            };

            libraries = {
              Movies = {
                collectionType = "movies";
                paths = [ "/mnt/main/main-encrypted/homelab/media/movies" ];
              };
              Shows = {
                collectionType = "tvshows";
                paths = [ "/mnt/main/main-encrypted/homelab/media/tv" ];
              };
            };

            system.pluginRepositories = {
              "SSO" = {
                url = "https://raw.githubusercontent.com/K0lin/jellyfin-plugin-sso/${ssoRev}/manifest.json";
                hash = ssoManifestHash;
              };
            };

            plugins."SSO Authentication" = {
              enable = true;
              apiName = "SSO-Auth";
              package = inputs.nixflix.lib.jellyfinPlugins.fromRepo {
                version = "5.1.1";
                hash = "sha256-QYzyg8pJvsLvmJbgOujhms7vY7BmLlqgcndxqNGyJcI=";
                repository = "SSO";
              };
              config = {
                OidConfigs = {
                  pocketid = {
                    Enabled = true;
                    EnableAuthorization = true;
                    EnableAllFolders = true;
                    OidEndpoint = "https://${config.nixicle.domains.sso}/.well-known/openid-configuration";
                    OidClientId._secret = config.sops.secrets."jellyfin/client_id".path;
                    OidSecret._secret = config.sops.secrets."jellyfin/client_secret".path;
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
                <form action="https://jellyfin.${config.nixicle.domains.root}/sso/OID/p/pocketid">
                  <button class="raised block emby-button button-submit">
                    Sign in with SSO
                  </button>
                </form>
              '';
              customCss = ''
                @import url("https://theme-park.dev/css/base/jellyfin/catppuccin-macchiato.css");
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
              password._secret = config.sops.secrets."jellyfin/admin_password".path;
            };
          };
        };

        hardware.graphics = {
          enable = true;
          extraPackages = [ pkgs.intel-media-driver ];
        };
        boot.kernelModules = [ "i915" ];
      };
  };
}
