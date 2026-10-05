{ inputs, ... }:
{
  flake-file.inputs.nixflix = {
    url = "github:kiriwalawren/nixflix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake-file.inputs.flowfin-sso = {
    url = "github:K0lin/jellyfin-plugin-sso/manifest-release";
    flake = false;
  };

  den.aspects.nixflix = {
    nixos =
      {
        config,
        lib,
        ...
      }:
      let
        flowfinManifest = "${inputs.flowfin-sso}/manifest.json";
        flowfinRev = inputs.flowfin-sso.rev;
        flowfinManifestHash = builtins.convertHash {
          hash = builtins.hashFile "sha256" flowfinManifest;
          hashAlgo = "sha256";
          toHashFormat = "nix32";
        };
      in
      {
        imports = [ inputs.nixflix.nixosModules.nixflix ];

        systemd.services = {
          qbittorrent.preStart = lib.mkBefore ''
            mkdir -p '${config.services.qbittorrent.profileDir}/qBittorrent/config'
          '';

          jellyfin-libraries.enable = lib.mkForce false;

          jellyfin-plugins.serviceConfig = {
            Restart = "on-failure";
            RestartSec = 5;
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
            name = "catppuccin-macchiato";
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
              indexers = [
                { name = "Torrent Downloads"; }
                { name = "TorrentDownload"; }
                { name = "TorrentKitty"; }
                { name = "The Pirate Bay"; }
              ];
            };
          };

          jellyfin = {
            enable = true;
            apiKey._secret = config.sops.secrets."jellyfin/api_key".path;

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
                "SSO" = {
                  url = "https://raw.githubusercontent.com/K0lin/jellyfin-plugin-sso/${flowfinRev}/manifest.json";
                  hash = flowfinManifestHash;
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
                  version = "5.1.1";
                  hash = "sha256-2xJrR2O9o6N1T6IQMjL8A+8b+SnP7aNfLprznIdSM7E=";
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
                      SchemeOverride = "https";
                    };
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
                password._secret = config.sops.secrets."jellyfin/admin_password".path;
              };
            };
          };

          seerr = {
            enable = true;
            apiKey._secret = config.sops.secrets."jellyseerr/api_key".path;
            jellyfin = {
              # externalHostname = "https://jellyfin.${config.nixicle.domains.root}";
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
