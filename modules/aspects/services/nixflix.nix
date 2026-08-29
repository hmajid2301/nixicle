{ inputs, ... }:
{
  flake-file.inputs.nixflix = {
    url = "github:kiriwalawren/nixflix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.nixflix = {
    nixos =
      {
        config,
        lib,
        secrets,
        ...
      }:
      let
        secretPaths = lib.mergeAttrsList secrets;
      in
      {
        imports = [ inputs.nixflix.nixosModules.nixflix ];

        systemd.services = {
          qbittorrent.preStart = lib.mkBefore ''
            mkdir -p '${config.services.qbittorrent.profileDir}/qBittorrent/config'
          '';

          # TODO: jellyfin-libraries service fails on boot, disabled for now.
          # Fix properly later — needs to align with nixflix upstream changes
          # or rewrite the library provisioning script.
          jellyfin-libraries.enable = lib.mkForce false;
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

        sops.secrets = {
          "sonarr/api_key" = { };
          "sonarr/password" = { };
          "radarr/api_key" = { };
          "radarr/password" = { };
          "prowlarr/api_key" = { };
          "prowlarr/password" = { };
          "jellyfin/admin_password" = { };
          "jellyfin/api_key" = { };
          "jellyseerr/api_key" = { };
          "qbittorrent/password" = { };
          "sonarr-anime/api_key" = { };
          "sonarr-anime/password" = { };
          "opensubtitles/api-key" = { };
          "opensubtitles/password" = { };
          "jellyfin/client_id" = { };
          "jellyfin/client_secret" = { };
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
              apiKey._secret = secretPaths."sonarr/api_key";
              hostConfig = {
                password._secret = secretPaths."sonarr/password";
              };
            };
          };

          sonarr-anime = {
            enable = true;
            config = {
              apiKey._secret = secretPaths."sonarr-anime/api_key";
              hostConfig.password._secret = secretPaths."sonarr-anime/password";
            };
          };

          radarr = {
            enable = true;
            config = {
              apiKey._secret = secretPaths."radarr/api_key";
              hostConfig = {
                password._secret = secretPaths."radarr/password";
              };
            };
          };

          prowlarr = {
            enable = true;
            config = {
              apiKey._secret = secretPaths."prowlarr/api_key";
              hostConfig = {
                password._secret = secretPaths."prowlarr/password";
              };
              indexers = [
                { name = "Torrent Downloads"; }
                { name = "TorrentDownload"; }
                { name = "TorrentKitty"; }
                { name = "The Pirate Bay"; }
                { name = "showRSS"; }
              ];
            };
          };

          jellyfin = {
            enable = true;
            apiKey._secret = secretPaths."jellyfin/api_key";

            encoding = {
              hardwareAccelerationType = "vaapi";
              vaapiDevice = "/dev/dri/renderD128";
              enableHardwareEncoding = true;
            };

            system = {
              trickplayOptions = {
                enableHwAcceleration = true;
                enableHwEncoding = true;
                processPriority = "Idle";
                processThreads = 1;
              };
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
                  OpenSubPassword._secret = secretPaths."opensubtitles/password";
                  OpenSubApiKey._secret = secretPaths."opensubtitles/api-key";
                  EnableOpenSubtitles = true;
                  EnableYifySubtitles = true;
                  Cache.SubLifeInMinutes = "Always";
                };
              };

              "Open Subtitles" = {
                enable = true;
                config = {
                  Username = "b7n1mytj6@mozmail.com";
                  Password._secret = secretPaths."opensubtitles/password";
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
                      SchemeOverride = "https";
                    };
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
                  extractChapterImagesDuringLibraryScan = false;
                  extractTrickplayImagesDuringLibraryScan = false;
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
                password._secret = secretPaths."jellyfin/admin_password";
              };
            };
          };

          seerr = {
            enable = true;
            apiKey._secret = secretPaths."jellyseerr/api_key";
            jellyfin = {
              # externalHostname = "https://jellyfin.haseebmajid.dev";
            };
          };

          torrentClients.qbittorrent = {
            enable = true;
            password = {
              _secret = secretPaths."qbittorrent/password";
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
