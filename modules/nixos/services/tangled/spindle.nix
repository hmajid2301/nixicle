{
  config,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.tangled.spindle;
in
{
  options.services.nixicle.tangled.spindle = {
    enable = mkBoolOpt false "Enable a tangled spindle";

    package = mkOption {
      type = types.package;
      description = "Package to use for the spindle";
    };

    server = {
      listenAddr = mkOpt types.str "0.0.0.0:6555" "Address to listen on";

      dbPath = mkOption {
        type = types.path;
        default = "/var/lib/spindle/spindle.db";
        description = "Path to the database file";
      };

      hostname = mkOption {
        type = types.str;
        example = "my.spindle.com";
        description = "Hostname for the server (required)";
      };

      plcUrl = mkOpt types.str "https://plc.directory" "atproto PLC directory";

      jetstreamEndpoint = mkOpt types.str "wss://jetstream1.us-west.bsky.network/subscribe" "Jetstream endpoint to subscribe to";

      dev = mkBoolOpt false "Enable development mode (disables signature verification)";

      owner = mkOption {
        type = types.str;
        example = "did:plc:qfpnj4og54vl56wngdriaxug";
        description = "DID of owner (required)";
      };

      maxJobCount = mkOption {
        type = types.int;
        default = 2;
        example = 5;
        description = "Maximum number of concurrent jobs to run";
      };

      queueSize = mkOption {
        type = types.int;
        default = 100;
        example = 100;
        description = "Maximum number of jobs queue up";
      };

      secrets = {
        provider = mkOpt types.str "openbao" "Backend to use for secret management, valid options are 'sqlite', and 'openbao'.";

        openbao = {
          proxyAddr = mkOpt types.str "http://100.117.131.57:8200" "OpenBao proxy address";
          mount = mkOpt types.str "spindle" "OpenBao mount point";
        };
      };
    };

    pipelines = {
      nixery = mkOpt types.str "nixery.tangled.sh" "Nixery instance to use";
      workflowTimeout = mkOpt types.str "5m" "Timeout for each step of a pipeline";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;

    systemd.services.tangled-spindle = {
      description = "Tangled spindle service";
      after = [
        "network.target"
        "docker.service"
      ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        LogsDirectory = "spindle";
        StateDirectory = "spindle";
        Environment = [
          "SPINDLE_SERVER_LISTEN_ADDR=${cfg.server.listenAddr}"
          "SPINDLE_SERVER_DB_PATH=${cfg.server.dbPath}"
          "SPINDLE_SERVER_HOSTNAME=${cfg.server.hostname}"
          "SPINDLE_SERVER_PLC_URL=${cfg.server.plcUrl}"
          "SPINDLE_SERVER_JETSTREAM_ENDPOINT=${cfg.server.jetstreamEndpoint}"
          "SPINDLE_SERVER_DEV=${boolToString cfg.server.dev}"
          "SPINDLE_SERVER_OWNER=${cfg.server.owner}"
          "SPINDLE_SERVER_MAX_JOB_COUNT=${toString cfg.server.maxJobCount}"
          "SPINDLE_SERVER_QUEUE_SIZE=${toString cfg.server.queueSize}"
          "SPINDLE_SERVER_SECRETS_PROVIDER=${cfg.server.secrets.provider}"
          "SPINDLE_SERVER_SECRETS_OPENBAO_PROXY_ADDR=${cfg.server.secrets.openbao.proxyAddr}"
          "SPINDLE_SERVER_SECRETS_OPENBAO_MOUNT=${cfg.server.secrets.openbao.mount}"
          "SPINDLE_NIXERY_PIPELINES_NIXERY=${cfg.pipelines.nixery}"
          "SPINDLE_NIXERY_PIPELINES_WORKFLOW_TIMEOUT=${cfg.pipelines.workflowTimeout}"
        ];
        ExecStart = "${cfg.package}/bin/spindle";
        Restart = "always";
      };
    };

    services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
      name = "spindle";
      port = 6555;
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        {
          directory = "/var/lib/spindle";
          mode = "0750";
        }
        {
          directory = "/var/log/spindle";
          mode = "0750";
        }
      ];
    };
  };
}
