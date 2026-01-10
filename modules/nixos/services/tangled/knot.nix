{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.services.nixicle.tangled.knot;
in
{
  options.services.nixicle.tangled.knot = {
    enable = mkBoolOpt false "Enable a tangled knot";

    package = mkOption {
      type = types.package;
      description = "Package to use for the knot";
    };

    appviewEndpoint = mkOpt types.str "https://tangled.org" "Appview endpoint";

    gitUser = mkOpt types.str "git" "User that hosts git repos and performs git operations";

    openFirewall = mkBoolOpt true "Open port 22 in the firewall for ssh";

    stateDir = mkOption {
      type = types.path;
      default = "/home/${cfg.gitUser}";
      description = "Tangled knot data directory";
    };

    repo = {
      scanPath = mkOption {
        type = types.path;
        default = cfg.stateDir;
        description = "Path where repositories are scanned from";
      };

      readme = mkOption {
        type = types.listOf types.str;
        default = [
          "README.md"
          "readme.md"
          "README"
          "readme"
          "README.markdown"
          "readme.markdown"
          "README.txt"
          "readme.txt"
          "README.rst"
          "readme.rst"
          "README.org"
          "readme.org"
          "README.asciidoc"
          "readme.asciidoc"
        ];
        description = "List of README filenames to look for (in priority order)";
      };

      mainBranch = mkOpt types.str "main" "Default branch name for repositories";
    };

    git = {
      userName = mkOpt types.str "Tangled" "Git user name used as committer";
      userEmail = mkOpt types.str "noreply@tangled.org" "Git user email used as committer";
    };

    motd = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Message of the day

        The contents are shown as-is; eg. you will want to add a newline if
        setting a non-empty message since the knot won't do this for you.
      '';
    };

    motdFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        File containing message of the day

        The contents are shown as-is; eg. you will want to add a newline if
        setting a non-empty message since the knot won't do this for you.
      '';
    };

    server = {
      listenAddr = mkOpt types.str "0.0.0.0:5555" "Address to listen on";

      internalListenAddr = mkOpt types.str "127.0.0.1:5444" "Internal address for inter-service communication";

      owner = mkOption {
        type = types.str;
        example = "did:plc:qfpnj4og54vl56wngdriaxug";
        description = "DID of owner (required)";
      };

      dbPath = mkOption {
        type = types.path;
        default = "${cfg.stateDir}/knotserver.db";
        description = "Path to the database file";
      };

      hostname = mkOption {
        type = types.str;
        example = "my.knot.com";
        description = "Hostname for the server (required)";
      };

      plcUrl = mkOpt types.str "https://plc.directory" "atproto PLC directory";

      jetstreamEndpoint = mkOpt types.str "wss://jetstream1.us-west.bsky.network/subscribe" "Jetstream endpoint to subscribe to";

      logDids = mkBoolOpt true "Enable logging of DIDs";

      dev = mkBoolOpt false "Enable development mode (disables signature verification)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.git
      cfg.package
    ];

    users.users.${cfg.gitUser} = {
      isSystemUser = true;
      useDefaultShell = true;
      home = cfg.stateDir;
      createHome = true;
      group = cfg.gitUser;
    };

    users.groups.${cfg.gitUser} = { };

    services.openssh = {
      enable = true;
      extraConfig = ''
        Match User ${cfg.gitUser}
        AuthorizedKeysCommand /etc/ssh/keyfetch_wrapper
        AuthorizedKeysCommandUser nobody
        ChallengeResponseAuthentication no
        PasswordAuthentication no
      '';
    };

    environment.etc."ssh/keyfetch_wrapper" = {
      mode = "0555";
      text = ''
        #!${pkgs.stdenv.shell}
        ${cfg.package}/bin/knot keys \
          -output authorized-keys \
          -internal-api "http://${cfg.server.internalListenAddr}" \
          -git-dir "${cfg.repo.scanPath}" \
          -log-path /tmp/knotguard.log
      '';
    };

    systemd.services.tangled-knot = {
      description = "Tangled knot service";
      after = [
        "network.target"
        "sshd.service"
      ];
      wantedBy = [ "multi-user.target" ];

      preStart =
        let
          setMotd =
            if cfg.motdFile != null && cfg.motd != null then
              throw "motdFile and motd cannot be both set"
            else
              ''
                ${optionalString (cfg.motdFile != null) "cat ${cfg.motdFile} > ${cfg.stateDir}/motd"}
                ${optionalString (cfg.motd != null) ''printf "${cfg.motd}" > ${cfg.stateDir}/motd''}
              '';
        in
        ''
          mkdir -p "${cfg.repo.scanPath}"
          chown -R ${cfg.gitUser}:${cfg.gitUser} "${cfg.repo.scanPath}"

          mkdir -p "${cfg.stateDir}/.config/git"
          cat > "${cfg.stateDir}/.config/git/config" << EOF
          [user]
          name = ${cfg.git.userName}
          email = ${cfg.git.userEmail}
          [receive]
          advertisePushOptions = true
          [uploadpack]
          allowFilter = true
          EOF
          ${setMotd}
          chown -R ${cfg.gitUser}:${cfg.gitUser} "${cfg.stateDir}"
        '';

      serviceConfig = {
        User = cfg.gitUser;
        PermissionsStartOnly = true;
        WorkingDirectory = cfg.stateDir;
        Environment = [
          "KNOT_REPO_SCAN_PATH=${cfg.repo.scanPath}"
          "KNOT_REPO_README=${concatStringsSep "," cfg.repo.readme}"
          "KNOT_REPO_MAIN_BRANCH=${cfg.repo.mainBranch}"
          "KNOT_GIT_USER_NAME=${cfg.git.userName}"
          "KNOT_GIT_USER_EMAIL=${cfg.git.userEmail}"
          "APPVIEW_ENDPOINT=${cfg.appviewEndpoint}"
          "KNOT_SERVER_INTERNAL_LISTEN_ADDR=${cfg.server.internalListenAddr}"
          "KNOT_SERVER_LISTEN_ADDR=${cfg.server.listenAddr}"
          "KNOT_SERVER_DB_PATH=${cfg.server.dbPath}"
          "KNOT_SERVER_HOSTNAME=${cfg.server.hostname}"
          "KNOT_SERVER_PLC_URL=${cfg.server.plcUrl}"
          "KNOT_SERVER_JETSTREAM_ENDPOINT=${cfg.server.jetstreamEndpoint}"
          "KNOT_SERVER_OWNER=${cfg.server.owner}"
          "KNOT_SERVER_LOG_DIDS=${if cfg.server.logDids then "true" else "false"}"
          "KNOT_SERVER_DEV=${if cfg.server.dev then "true" else "false"}"
        ];
        ExecStart = "${cfg.package}/bin/knot server";
        Restart = "always";
      };
    };

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 22 ];

    services.traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
      name = "tangled";
      port = 5555;
    };

    environment.persistence."/persist" = mkIf config.system.impermanence.enable {
      directories = [
        {
          directory = cfg.stateDir;
          user = cfg.gitUser;
          group = cfg.gitUser;
          mode = "0750";
        }
      ];
    };
  };
}
