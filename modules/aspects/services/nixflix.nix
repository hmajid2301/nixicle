{ inputs, lib, ... }:
let
  tunnelId = "ecef5dbb-834e-43ed-84c6-355a2ac53e59";
in
{
  flake-file.inputs.nixflix = {
    url = "github:kiriwalawren/nixflix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.nixflix = {
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ inputs.nixflix.nixosModules.nixflix ];

        systemd.services = {
          qbittorrent.preStart = lib.mkBefore ''
            mkdir -p '${config.services.qbittorrent.profileDir}/qBittorrent/config'
          '';

          jellyfin-libraries = lib.mkIf config.nixflix.jellyfin.enable {
            serviceConfig = {
              ExecStartPre = lib.mkBefore [
                "${lib.getExe' pkgs.util-linux "runuser"} -u haseeb -- mkdir -p /mnt/homelab/homelab/media/anime /mnt/homelab/homelab/media/movies /mnt/homelab/homelab/media/tv"
              ];
            };
            script = lib.mkForce ''
              set -eu

              BASE_URL="http://127.0.0.1:8096"

              echo "Configuring Jellyfin libraries..."

              # Find and run original script, skipping mkdir lines
              ORIGINAL=$(ls /nix/store/*-unit-script-jellyfin-libraries-start/bin/jellyfin-libraries-start 2>/dev/null | head -1)
              if [ -n "$ORIGINAL" ] && [ -x "$ORIGINAL" ]; then
                # Remove lines from "Creating library paths..." through the last mkdir echo
                # Use $BASH since it's not in the service's PATH
                sed -e '/^echo "Creating library paths..."/,/^echo "Created path: \/mnt\/homelab\/homelab\/media\/tv"/d' "$ORIGINAL" | "$BASH"
              else
                echo "Warning: Original jellyfin-libraries-start script not found" >&2
              fi
            '';
          };
        };

        environment.etc =
          let
            override = paths: {
              text = builtins.concatStringsSep "\n" (map (path: "d ${path} 0775 root media - -") paths) + "\n";
            };
          in
          {
            "tmpfiles.d/10-nixflix.conf" = override [
              "/data/.state"
              "/data/downloads"
            ];
            "tmpfiles.d/10-sonarr.conf" = override [ "/data/.state/sonarr" ];
            "tmpfiles.d/10-radarr.conf" = override [ "/data/.state/radarr" ];
          };

        sops.secrets =
          let
            sopsFile = ../../../modules/nixos/services/secrets.yaml;
          in
          {
            "sonarr/api_key" = { inherit sopsFile; };
            "sonarr/password" = { inherit sopsFile; };
            "radarr/api_key" = { inherit sopsFile; };
            "radarr/password" = { inherit sopsFile; };
            "prowlarr/api_key" = { inherit sopsFile; };
            "prowlarr/password" = { inherit sopsFile; };
            "jellyfin/admin_password" = { inherit sopsFile; };
            "jellyfin/api_key" = { inherit sopsFile; };
            "jellyseerr/api_key" = { inherit sopsFile; };
            "qbittorrent/password" = { inherit sopsFile; };
            "sonarr-anime/api_key" = { inherit sopsFile; };
            "sonarr-anime/password" = { inherit sopsFile; };
            "opensubtitles/api-key" = { inherit sopsFile; };
            "opensubtitles/password" = { inherit sopsFile; };
            "jellyfin/client_id" = { inherit sopsFile; };
            "jellyfin/client_secret" = { inherit sopsFile; };
          };

        nixflix = {
          enable = true;
          mediaDir = "/mnt/homelab/homelab/media";
          stateDir = "/data/.state";
          mediaUsers = [ "haseeb" ];

          theme = {
            enable = true;
            name = "catppuccin-mocchiato";
          };

          postgres.enable = false;

          flaresolverr.enable = true;

          sonarr = {
            enable = true;
            config = {
              apiKey._secret = config.sops.secrets."sonarr/api_key".path;
              hostConfig = {
                password._secret = config.sops.secrets."sonarr/password".path;
              };
            };
          };

          sonarr-anime = {
            enable = true;
            config = {
              apiKey._secret = config.sops.secrets."sonarr-anime/api_key".path;
              hostConfig.password._secret = config.sops.secrets."sonarr-anime/password".path;
            };
          };

          radarr = {
            enable = true;
            config = {
              apiKey._secret = config.sops.secrets."radarr/api_key".path;
              hostConfig = {
                password._secret = config.sops.secrets."radarr/password".path;
              };
            };
          };

          prowlarr = {
            enable = true;
            config = {
              apiKey._secret = config.sops.secrets."prowlarr/api_key".path;
              hostConfig = {
                password._secret = config.sops.secrets."prowlarr/password".path;
              };
            };
          };

          jellyfin = {
            enable = true;
            apiKey._secret = config.sops.secrets."jellyfin/api_key".path;

            system = {
              pluginRepositories = {
                "SSO-Auth" = {
                  url = "https://raw.githubusercontent.com/9p4/jellyfin-plugin-sso/manifest-release/manifest.json";
                  hash = "sha256-lX45HueVfT/xfIxkYn5eQobmVXBoi5jdpJCx43edRA0=";
                };
              };
            };

            plugins = {
              subbuzz = {
                enable = true;
                config = {
                  OpenSubUserName = "b7n1mytj6@mozmail.com";
                  OpenSubPassword._secret = config.sops.secrets."opensubtitles/password".path;
                  OpenSubApiKey._secret = config.sops.secrets."opensubtitles/api-key".path;
                  EnableOpenSubtitles = true;
                  EnableYifySubtitles = true;
                  Cache.SubLifeInMinutes = "Always";
                };
              };

              "Open Subtitles" = {
                enable = true;
                config = {
                  Username = "b7n1mytj6@mozmail.com";
                  Password._secret = config.sops.secrets."opensubtitles/password".path;
                };
              };

              "Subtitle Extract" = {
                enable = true;
                config.ExtractionDuringLibraryScan = true;
              };

              "SSO Authentication" = {
                enable = true;
                apiName = "SSO-Auth";
                package = inputs.nixflix.lib.jellyfinPlugins.fromRepo {
                  version = "4.0.0.4";
                  hash = "sha256-MJTyE6CeVLk7mlugauJ/F6bpi1kYwNtzNmQeH3+CFeQ=";
                  repository = "SSO-Auth";
                };
                config = {
                  OidConfigs = {
                    authentik = {
                      Enabled = true;
                      EnableAuthorization = true;
                      EnableAllFolders = true;
                      OidEndpoint = "https://authentik.haseebmajid.dev/application/o/jellyfin/.well-known/openid-configuration";
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
                      SchemeOverride = "https";
                    };
                  };
                };
              };
            };

            branding = {
              loginDisclaimer = ''
                <form action="https://jellyfin.haseebmajid.dev/sso/OID/p/authentik">
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

            libraries =
              let
                subtitleSettings = {
                  disabledSubtitleFetchers = [ "subbuzz" ];
                  subtitleFetcherOrder = [
                    "subbuzz"
                    "Open Subtitles"
                  ];
                  subtitleDownloadLanguages = [
                    "eng"
                    "spa"
                  ];
                  saveSubtitlesWithMedia = true;
                  allowEmbeddedSubtitles = "AllowAll";
                  requirePerfectSubtitleMatch = true;
                  skipSubtitlesIfAudioTrackMatches = false;
                  skipSubtitlesIfEmbeddedSubtitlesPresent = true;
                };
              in
              {
                Shows = subtitleSettings;
                Anime = subtitleSettings;
                Movies = subtitleSettings;
              };

            users = {
              admin = {
                mutable = false;
                policy.isAdministrator = true;
                password._secret = config.sops.secrets."jellyfin/admin_password".path;
              };
            };
          };

          seerr = {
            enable = true;
            apiKey._secret = config.sops.secrets."jellyseerr/api_key".path;
            jellyfin = {
              # externalHostname = "https://jellyfin.haseebmajid.dev";
            };
          };

          torrentClients.qbittorrent = {
            enable = true;
            password = {
              _secret = config.sops.secrets."qbittorrent/password".path;
            };
            # TODO: Move Password_PBKDF2 to sops once nixflix/nixpkgs supports _secret for serverConfig.
            # Currently must be a static string because serverConfig is a freeform type written at build time.
            # Regenerate with: nix run git+https://codeberg.org/feathecutie/qbittorrent_password -- -p <password>
            # Track: https://github.com/kiriwalawren/nixflix/issues/129
            serverConfig = {
              Preferences.WebUI.Username = "admin";
              Preferences.WebUI.Password_PBKDF2 = "@ByteArray(0P0r0jPjyptyTKRvp/aALw==:x12IgAVqcmzDv9sQBxNTM7K6g3tfhANo7BszXY06wITON0xk4uM7efzREPZ7xS4LHHiHNRMoEkJuRCB2S9628Q==)";
            };
          };

          recyclarr.enable = true;

          downloadarr = {
            enable = true;
            qbittorrent.enable = true;
          };
        };

        services.cloudflared.tunnels."${tunnelId}".ingress."seerr.haseebmajid.dev" =
          "http://localhost:5055";

        services.traefik.dynamicConfigOptions.http = lib.mkMerge [
          (lib.nixicle.mkAuthenticatedTraefikService {
            name = "sonarr";
            port = 8989;
          })
          (lib.nixicle.mkAuthenticatedTraefikService {
            name = "sonarr-anime";
            port = 8990;
          })
          (lib.nixicle.mkAuthenticatedTraefikService {
            name = "radarr";
            port = 7878;
          })
          (lib.nixicle.mkAuthenticatedTraefikService {
            name = "prowlarr";
            port = 9696;
          })
          (lib.nixicle.mkTraefikService {
            name = "seerr";
            port = 5055;
          })
          (lib.nixicle.mkTraefikService {
            name = "jellyfin";
            port = 8096;
          })
        ];
      };
  };
}
