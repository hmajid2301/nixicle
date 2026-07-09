{ den, ... }:
{
  den.aspects.hardening-vps = {
    includes = [ ];
    nixos =
      { config, lib, ... }:
      let
        mkCoreServiceHardening = {
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
        };
      in
      {
        security.sudo = {
          wheelNeedsPassword = true;
          execWheelOnly = true;
          extraConfig = ''
            Defaults passwd_tries=3
            Defaults timestamp_timeout=5
          '';
        };

        services = {
          openssh.openFirewall = lib.mkForce false;
          openssh.settings = {
            PermitRootLogin = "no";
            KbdInteractiveAuthentication = false;
            AllowUsers = [ "nixos" ];
            AllowAgentForwarding = false;
            AllowTcpForwarding = false;
            AllowStreamLocalForwarding = false;
            X11Forwarding = false;
            GatewayPorts = "no";
            LoginGraceTime = 30;
            MaxAuthTries = 3;
            MaxSessions = 2;
            MaxStartups = "10:30:60";
            UseDns = false;
          };
          journald.extraConfig = ''
            SystemMaxUse=1G
            RuntimeMaxUse=256M
            MaxRetentionSec=14day
            Compress=yes
            Storage=persistent
          '';
        };

        security.auditd.enable = true;
        security.audit.enable = true;
        security.audit.rules = [
          "-a exit,always -F arch=b64 -S execve"
        ];

        boot.kernel.sysctl = {
          "fs.protected_fifos" = 2;
          "fs.protected_regular" = 2;
          "fs.suid_dumpable" = 0;
          "kernel.dmesg_restrict" = 1;
          "kernel.kptr_restrict" = 2;
          "kernel.unprivileged_bpf_disabled" = 1;
          "net.core.bpf_jit_harden" = 2;
          "net.ipv4.conf.all.rp_filter" = 1;
          "net.ipv4.conf.default.rp_filter" = 1;
          "net.ipv4.tcp_syncookies" = 1;
        };

        systemd.services = lib.mkMerge [
          (lib.mkIf config.services.pocket-id.enable {
            pocket-id.serviceConfig = mkCoreServiceHardening;
          })
          (lib.mkIf config.services.traefik.enable {
            traefik.serviceConfig = mkCoreServiceHardening;
          })
          (lib.mkIf config.services.openbao.enable {
            openbao.serviceConfig = mkCoreServiceHardening;
          })
          (lib.mkIf config.services.postgresql.enable {
            postgresql.serviceConfig = mkCoreServiceHardening;
          })
          (lib.mkIf (config.services.redis.servers ? valkey && config.services.redis.servers.valkey.enable) {
            redis-valkey.serviceConfig = mkCoreServiceHardening;
          })
        ];
      };
  };
}
