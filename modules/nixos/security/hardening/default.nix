{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.security.nixicle.hardening;
in
{
  options.security.nixicle.hardening = {
    enable = mkEnableOption "Enable system hardening";
  };

  config = mkIf cfg.enable {
    boot.kernel.sysctl = {
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.suid_dumpable" = 0;

      "kernel.kptr_restrict" = 2;
      "kernel.sysrq" = 0;
      "kernel.unprivileged_bpf_disabled" = 1;

      "net.core.bpf_jit_harden" = 2;
      "net.ipv4.conf.all.rp_filter" = 1;
      "net.ipv4.conf.all.log_martians" = 1;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.default.log_martians" = 1;
      "net.ipv6.conf.all.accept_redirects" = 0;
      "net.ipv6.conf.default.accept_redirects" = 0;
    };

    boot.blacklistedKernelModules = [
      "dccp"
      "sctp"
      "rds"
      "tipc"
    ];

    boot.kernelParams = [
      "lsm=landlock,lockdown,yama,integrity,apparmor,bpf"
    ];

    fileSystems."/proc" = mkIf (!config.roles.desktop.enable) {
      device = "proc";
      fsType = "proc";
      options = [ "hidepid=2" "gid=proc" ];
    };

    users.groups.proc = mkIf (!config.roles.desktop.enable) {};

    services.dbus.implementation = mkIf (!config.roles.desktop.enable) "broker";

    security.sudo.execWheelOnly = true;
  };
}
