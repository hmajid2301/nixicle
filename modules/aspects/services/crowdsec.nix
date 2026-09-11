_: {
  den.aspects.crowdsec = {
    persist.directories = [
      {
        directory = "/var/lib/crowdsec";
        user = "crowdsec";
        group = "crowdsec";
        mode = "0750";
      }
    ];

    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.nixicle.crowdsec;
        yaml = pkgs.formats.yaml { };

        allowlistYaml = yaml.generate "nixicle-allowlist.yaml" {
          name = "nixicle/allowlist";
          description = "Whitelist own host and private ranges";
          whitelist = {
            reason = "trusted self and private traffic";
            ip = lib.filter (e: !lib.hasInfix "/" e) cfg.allowlist;
            cidr = [
              "127.0.0.0/8"
              "10.0.0.0/8"
              "172.16.0.0/12"
              "192.168.0.0/16"
              "100.64.0.0/10"
            ]
            ++ (lib.filter (e: lib.hasInfix "/" e) cfg.allowlist);
          }
          // lib.optionalAttrs (cfg.allowlistUris != [ ]) {
            expression = map (uri: "evt.Parsed.request == '${uri}'") cfg.allowlistUris;
          };
        };

        tunedHttpProbing = yaml.generate "http-probing.yaml" {
          type = "leaky";
          name = "crowdsecurity/http-probing";
          description = "Detect site scanning/probing from a single ip";
          filter = "evt.Meta.service == 'http' && evt.Meta.http_status in ['404', '403', '400'] && evt.Parsed.static_ressource == 'false' && !(evt.Meta.http_path startsWith '/api/document')";
          groupby = "evt.Meta.source_ip + '/' + evt.Parsed.target_fqdn";
          distinct = "evt.Meta.http_path";
          capacity = 100;
          reprocess = true;
          leakspeed = "10s";
          blackhole = "5m";
          labels = {
            remediation = true;
            classification = [ "attack.T1595" ];
            behavior = "http:scan";
            label = "HTTP Probing";
            spoofable = 0;
            service = "http";
            confidence = 1;
          };
        };

        tunedHttpCrawl = yaml.generate "http-crawl-non_statics.yaml" {
          type = "leaky";
          name = "crowdsecurity/http-crawl-non_statics";
          description = "Detect aggressive crawl on non static resources";
          filter = "evt.Meta.log_type in ['http_access-log', 'http_error-log'] && evt.Parsed.static_ressource == 'false' && evt.Parsed.verb in ['GET', 'HEAD']";
          distinct = "evt.Parsed.file_name";
          leakspeed = "1s";
          capacity = 200;
          cache_size = 5;
          groupby = "evt.Meta.source_ip + '/' + evt.Parsed.target_fqdn";
          blackhole = "1m";
          labels = {
            confidence = 1;
            spoofable = 0;
            classification = [ "attack.T1595" ];
            behavior = "http:crawl";
            service = "http";
            label = "Aggressive Crawl";
            remediation = true;
          };
        };
      in
      {
        options.nixicle.crowdsec.allowlist = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            Extra IPs or CIDRs CrowdSec should never ban (private and CGNAT
            ranges are always whitelisted).
          '';
          example = [ "82.165.193.60" ];
        };

        options.nixicle.crowdsec.allowlistUris = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = ''
            URL paths CrowdSec should never alert on, regardless of source
            IP. Useful for endpoints that legitimately return 403s to
            dynamic-IP clients, e.g. attic pushes with stale credentials.
          '';
          example = [ "/api/add" ];
        };

        config = {
          sops.secrets.crowdsec_enroll_key = { };
          sops.secrets.crowdsec_bouncer_key = { };

          # The upstream NixOS firewall-bouncer registration unit calls raw cscli,
          # which defaults to /etc/crowdsec/config.yaml instead of the NixOS-generated
          # config path. Provide that conventional path so auto-registration works.
          environment.etc."crowdsec/config.yaml".source =
            yaml.generate "crowdsec.yaml" config.services.crowdsec.settings.general;

          # Local parsers written via environment.etc keep a stable filename, so
          # content edits swap the symlink instead of accumulating stale
          # hash-named files (services.crowdsec.localConfig tmpfiles L+ links
          # never clean old ones, and duplicate parser names crash the engine).
          environment.etc."crowdsec/parsers/s02-enrich/nixicle-allowlist.yaml".source = allowlistYaml;
          systemd = {
            services = {
              crowdsec = {
                restartTriggers = [ allowlistYaml ];
                serviceConfig = {
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  PrivateDevices = true;
                  ProtectHome = true;
                  ProtectKernelLogs = true;
                  ProtectKernelTunables = true;
                  ProtectControlGroups = true;
                  ProtectKernelModules = true;
                  RestrictSUIDSGID = true;
                  LockPersonality = true;
                  RestrictNamespaces = true;
                  RestrictRealtime = true;
                  SystemCallArchitectures = "native";
                  ExecStartPre = lib.mkAfter [
                    (pkgs.writeShellScript "crowdsec-tune-scenarios" ''
                      set -euo pipefail
                      ${lib.getExe' pkgs.coreutils "install"} -m 600 \
                        ${tunedHttpProbing} /var/lib/crowdsec/state/hub/scenarios/crowdsecurity/http-probing.yaml
                      ${lib.getExe' pkgs.coreutils "install"} -m 600 \
                        ${tunedHttpCrawl} /var/lib/crowdsec/state/hub/scenarios/crowdsecurity/http-crawl-non_statics.yaml
                    '')
                  ];
                };
              };

              crowdsec-firewall-bouncer = {
                serviceConfig = {
                  DynamicUser = lib.mkForce false;
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  PrivateDevices = true;
                  ProtectHome = true;
                  ProtectKernelLogs = true;
                  ProtectKernelTunables = true;
                  ProtectControlGroups = true;
                  ProtectKernelModules = true;
                  RestrictSUIDSGID = true;
                  LockPersonality = true;
                  RestrictNamespaces = true;
                  RestrictRealtime = true;
                  SystemCallArchitectures = "native";
                  ExecStartPre = lib.mkBefore [
                    (pkgs.writeShellScript "wait-for-crowdsec-lapi" ''
                      set -euo pipefail
                      for i in $(seq 1 60); do
                        if ${lib.getExe pkgs.curl} -fsS http://127.0.0.1:8081/health >/dev/null 2>&1; then
                          exit 0
                        fi
                        sleep 1
                      done
                      echo "CrowdSec local API not ready" >&2
                      exit 1
                    '')
                  ];
                };
                after = [ "crowdsec-register-firewall-bouncer.service" ];
                requires = [ "crowdsec-register-firewall-bouncer.service" ];
              };

              crowdsec-register-firewall-bouncer = {
                description = "Register the CrowdSec firewall bouncer API key";
                wantedBy = [ "multi-user.target" ];
                after = [ "crowdsec.service" ];
                wants = [ "crowdsec.service" ];
                serviceConfig = {
                  Type = "oneshot";
                  NoNewPrivileges = true;
                  PrivateTmp = true;
                  ProtectHome = true;
                  ProtectKernelLogs = true;
                  ProtectKernelTunables = true;
                  ProtectControlGroups = true;
                  ProtectKernelModules = true;
                  RestrictSUIDSGID = true;
                  LockPersonality = true;
                  RestrictNamespaces = true;
                  RestrictRealtime = true;
                  SystemCallArchitectures = "native";
                };
                path = [ config.services.crowdsec.package ];
                script = ''
                  set -euo pipefail
                  name="crowdsec-firewall-bouncer"
                  key="$(cat ${config.sops.secrets.crowdsec_bouncer_key.path})"
                  cscli -c /etc/crowdsec/config.yaml bouncers delete "$name" --ignore-missing >/dev/null
                  cscli -c /etc/crowdsec/config.yaml bouncers add "$name" --key "$key" --output raw >/dev/null
                '';
              };
            };
          };

          services.crowdsec-firewall-bouncer = {
            enable = true;
            registerBouncer.enable = false;
            secrets.apiKeyPath = config.sops.secrets.crowdsec_bouncer_key.path;
          };

          services.crowdsec = {
            enable = true;
            hub.collections = [
              "crowdsecurity/linux"
              "crowdsecurity/sshd"
              "crowdsecurity/traefik"
            ];
            settings = {
              general.api = {
                server = {
                  enable = true;
                  listen_uri = "127.0.0.1:8081";
                };
                client.credentials_path = "/var/lib/crowdsec/state/lapi-secrets.yaml";
              };
              lapi.credentialsFile = "/var/lib/crowdsec/state/lapi-secrets.yaml";
              console.tokenFile = config.sops.secrets.crowdsec_enroll_key.path;
            };
            localConfig.acquisitions = [
              {
                source = "journalctl";
                journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
                labels.type = "syslog";
              }
              {
                source = "journalctl";
                journalctl_filter = [ "_SYSTEMD_UNIT=traefik.service" ];
                labels.type = "traefik";
              }
            ];
          };
        };
      };
  };
}
