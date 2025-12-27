{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.security.nixicle.auditd;
in
{
  options.security.nixicle.auditd = {
    enable = mkEnableOption "Enable auditd for system auditing";
  };

  config = mkIf cfg.enable {
    security.auditd.enable = true;
    security.audit = {
      enable = true;
      rules = [
        "-a exit,always -F arch=b64 -S execve"
        "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change"
        "-w /etc/sudoers -p wa -k sudoers_changes"
        "-w /etc/passwd -p wa -k passwd_changes"
        "-w /etc/group -p wa -k group_changes"
        "-w /etc/shadow -p wa -k shadow_changes"
        "-w /etc/ssh/sshd_config -p wa -k sshd_config_changes"
      ];
    };

    environment.persistence = mkIf config.system.impermanence.enable {
      "/persist" = {
        directories = [
          "/var/log/audit"
        ];
      };
    };
  };
}
