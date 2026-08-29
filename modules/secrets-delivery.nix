{ den, lib, ... }:
let
  inherit (den.lib.policy) pipe;
  mergeOne = vals: [ (lib.mergeAttrsList vals) ];
in
{
  den = {
    quirks.secrets = {
      description = "Per-aspect secret path delivery";
    };

    policies = {
      crowdsec-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append { crowdsec_enroll_key = "/run/secrets/crowdsec_enroll_key"; })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.crowdsec ])
        ])
      ];

      traefik-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append { cloudflare_api_key = "/run/secrets/cloudflare_api_key"; })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.traefik ])
        ])
      ];

      openbao-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append { openbao_static_seal_key = "/run/secrets/openbao_static_seal_key"; })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.openbao ])
        ])
      ];

      pocketid-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append {
            pocketid_encryption_key = "/run/secrets/pocketid_encryption_key";
            pocketid_static_api_key = "/run/secrets/pocketid_static_api_key";
          })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.pocketid ])
        ])
      ];

      searx-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append { searx_secret_key = "/run/secrets/searx_secret_key"; })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.searx ])
        ])
      ];

      attic-server-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append { attic = "/run/secrets/attic"; })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.attic-server ])
        ])
      ];

      btrbk-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append {
            b2_access_key = "/run/secrets/b2_access_key";
            b2_secret_key = "/run/secrets/b2_secret_key";
          })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.btrbk ])
        ])
      ];

      backup-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append {
            restic_password = "/run/secrets/restic_password";
            backblaze_env = "/run/secrets/backblaze_env";
            restic_repository = "/run/secrets/restic_repository";
          })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.backup-restic ])
        ])
      ];

      karakeep-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append { karakeep_oauth = "/run/secrets/karakeep_oauth"; })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.karakeep ])
        ])
      ];

      open-webui-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append { open_webui_oauth = "/run/secrets/open_webui_oauth"; })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.open-webui ])
        ])
      ];

      paperless-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append {
            paperless = "/run/secrets/paperless";
            paperless_pass = "/run/secrets/paperless_pass";
          })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.paperless ])
        ])
      ];

      tandoor-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append { tandoor = "/run/secrets/tandoor"; })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.tandoor ])
        ])
      ];

      homepage-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append { homepage_env = "/run/secrets/homepage_env"; })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.homepage ])
        ])
      ];

      immich-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append {
            "immich/client_id" = "/run/secrets/immich/client_id";
            "immich/client_secret" = "/run/secrets/immich/client_secret";
          })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.immich ])
        ])
      ];

      nixflix-secrets = _: [
        (pipe.from "secrets" [
          (pipe.filter (_: false))
          (pipe.append {
            "sonarr/api_key" = "/run/secrets/sonarr/api_key";
            "sonarr/password" = "/run/secrets/sonarr/password";
            "radarr/api_key" = "/run/secrets/radarr/api_key";
            "radarr/password" = "/run/secrets/radarr/password";
            "prowlarr/api_key" = "/run/secrets/prowlarr/api_key";
            "prowlarr/password" = "/run/secrets/prowlarr/password";
            "jellyfin/admin_password" = "/run/secrets/jellyfin/admin_password";
            "jellyfin/api_key" = "/run/secrets/jellyfin/api_key";
            "jellyseerr/api_key" = "/run/secrets/jellyseerr/api_key";
            "qbittorrent/password" = "/run/secrets/qbittorrent/password";
            "sonarr-anime/api_key" = "/run/secrets/sonarr-anime/api_key";
            "sonarr-anime/password" = "/run/secrets/sonarr-anime/password";
            "opensubtitles/api-key" = "/run/secrets/opensubtitles/api-key";
            "opensubtitles/password" = "/run/secrets/opensubtitles/password";
            "jellyfin/client_id" = "/run/secrets/jellyfin/client_id";
            "jellyfin/client_secret" = "/run/secrets/jellyfin/client_secret";
          })
          (pipe.for mergeOne)
          (pipe.to [ den.aspects.nixflix ])
        ])
      ];
    };

    schema.host.includes = [
      den.policies.crowdsec-secrets
      den.policies.traefik-secrets
      den.policies.openbao-secrets
      den.policies.pocketid-secrets
      den.policies.searx-secrets
      den.policies.attic-server-secrets
      den.policies.btrbk-secrets
      den.policies.backup-secrets
      den.policies.karakeep-secrets
      den.policies.open-webui-secrets
      den.policies.paperless-secrets
      den.policies.tandoor-secrets
      den.policies.homepage-secrets
      den.policies.immich-secrets
      den.policies.nixflix-secrets
    ];
  };
}
