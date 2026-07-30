{ den, lib, ... }:
let
  inherit (den.lib.policy) pipe;
  mergeOne = vals: [ (lib.mergeAttrsList vals) ];
in
{
  den.quirks.secrets = {
    description = "Per-aspect secret path delivery";
  };

  den.policies.crowdsec-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { crowdsec_enroll_key = "/run/secrets/crowdsec_enroll_key"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.crowdsec ])
      ])
    ];

  den.policies.traefik-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { cloudflare_api_key = "/run/secrets/cloudflare_api_key"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.traefik ])
      ])
    ];

  den.policies.openbao-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { openbao_static_seal_key = "/run/secrets/openbao_static_seal_key"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.openbao ])
      ])
    ];

  den.policies.pocketid-secrets =
    { host, ... }:
    [
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

  den.policies.cloudflare-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { cloudflared = "/run/secrets/cloudflared"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.cloudflare ])
      ])
    ];

  den.policies.searx-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { searx_secret_key = "/run/secrets/searx_secret_key"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.searx ])
      ])
    ];

  den.policies.atticd-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { attic = "/run/secrets/attic"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.atticd ])
      ])
    ];

  den.policies.btrbk-secrets =
    { host, ... }:
    [
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

  den.policies.backup-secrets =
    { host, ... }:
    [
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

  den.policies.karakeep-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { karakeep_oauth = "/run/secrets/karakeep_oauth"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.karakeep ])
      ])
    ];

  den.policies.open-webui-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { open_webui_oauth = "/run/secrets/open_webui_oauth"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.open-webui ])
      ])
    ];

  den.policies.paperless-secrets =
    { host, ... }:
    [
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

  den.policies.tandoor-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { tandoor = "/run/secrets/tandoor"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.tandoor ])
      ])
    ];

  den.policies.hortusfox-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { hortusfox_env = "/run/secrets/hortusfox_env"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.hortusfox ])
      ])
    ];

  den.policies.homepage-secrets =
    { host, ... }:
    [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append { homepage_env = "/run/secrets/homepage_env"; })
        (pipe.for mergeOne)
        (pipe.to [ den.aspects.homepage ])
      ])
    ];

  den.schema.host.includes = [
    den.policies.crowdsec-secrets
    den.policies.traefik-secrets
    den.policies.openbao-secrets
    den.policies.pocketid-secrets
    den.policies.cloudflare-secrets
    den.policies.searx-secrets
    den.policies.atticd-secrets
    den.policies.btrbk-secrets
    den.policies.backup-secrets
    den.policies.karakeep-secrets
    den.policies.open-webui-secrets
    den.policies.paperless-secrets
    den.policies.tandoor-secrets
    den.policies.hortusfox-secrets
    den.policies.homepage-secrets
  ];
}
