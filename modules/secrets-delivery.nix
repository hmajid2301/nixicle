{ den, lib, ... }:
let
  inherit (den.lib.policy) pipe;
  mergeOne = vals: [ (lib.mergeAttrsList vals) ];

  # Each entry delivers a set of SOPS secrets to an aspect as
  # { <secret> = "/run/secrets/<secret>"; }. The runtime path is always
  # /run/secrets/<name>, so the mapping is generated from the secret names.
  secretPolicies = [
    {
      name = "crowdsec";
      aspect = den.aspects.crowdsec;
      secrets = [ "crowdsec_enroll_key" ];
    }
    {
      name = "traefik";
      aspect = den.aspects.traefik;
      secrets = [ "cloudflare_api_key" ];
    }
    {
      name = "openbao";
      aspect = den.aspects.openbao;
      secrets = [ "openbao_static_seal_key" ];
    }
    {
      name = "pocketid";
      aspect = den.aspects.pocketid;
      secrets = [
        "pocketid_encryption_key"
        "pocketid_static_api_key"
      ];
    }
    {
      name = "searx";
      aspect = den.aspects.searx;
      secrets = [ "searx_secret_key" ];
    }
    {
      name = "attic-server";
      aspect = den.aspects.attic-server;
      secrets = [ "attic" ];
    }
    {
      name = "btrbk";
      aspect = den.aspects.btrbk;
      secrets = [
        "b2_access_key"
        "b2_secret_key"
      ];
    }
    {
      name = "backup";
      aspect = den.aspects.backup-restic;
      secrets = [
        "restic_password"
        "backblaze_env"
        "restic_repository"
      ];
    }
    {
      name = "karakeep";
      aspect = den.aspects.karakeep;
      secrets = [ "karakeep_oauth" ];
    }
    {
      name = "open-webui";
      aspect = den.aspects.open-webui;
      secrets = [ "open_webui_oauth" ];
    }
    {
      name = "paperless";
      aspect = den.aspects.paperless;
      secrets = [
        "paperless"
        "paperless_pass"
      ];
    }
    {
      name = "tandoor";
      aspect = den.aspects.tandoor;
      secrets = [ "tandoor" ];
    }
    {
      name = "homepage";
      aspect = den.aspects.homepage;
      secrets = [ "homepage_env" ];
    }
    {
      name = "immich";
      aspect = den.aspects.immich;
      secrets = [
        "immich/client_id"
        "immich/client_secret"
      ];
    }
    {
      name = "jellyfin";
      aspect = den.aspects.jellyfin;
      secrets = [
        "jellyfin/admin_password"
        "jellyfin/api_key"
        "jellyfin/client_id"
        "jellyfin/client_secret"
      ];
    }
    {
      name = "nixflix";
      aspect = den.aspects.nixflix;
      secrets = [
        "sonarr/api_key"
        "sonarr/password"
        "radarr/api_key"
        "radarr/password"
        "prowlarr/api_key"
        "prowlarr/password"
        "jellyfin/admin_password"
        "jellyfin/api_key"
        "jellyseerr/api_key"
        "qbittorrent/password"
        "sonarr-anime/api_key"
        "sonarr-anime/password"
        "opensubtitles/api-key"
        "opensubtitles/password"
        "jellyfin/client_id"
        "jellyfin/client_secret"
      ];
    }
  ];

  mkSecretPolicy =
    {
      name,
      aspect,
      secrets,
    }:
    lib.nameValuePair "${name}-secrets" (_: [
      (pipe.from "secrets" [
        (pipe.filter (_: false))
        (pipe.append (lib.genAttrs secrets (s: "/run/secrets/${s}")))
        (pipe.for mergeOne)
        (pipe.to [ aspect ])
      ])
    ]);

  generatedPolicies = builtins.listToAttrs (map mkSecretPolicy secretPolicies);
in
{
  den = {
    quirks.secrets = {
      description = "Per-aspect secret path delivery";
    };

    policies = generatedPolicies;

    schema.host.includes = map (p: den.policies."${p.name}-secrets") secretPolicies;
  };
}
