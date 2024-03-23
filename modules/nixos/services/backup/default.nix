{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.backup;
in {
  options.services.backup = {
    enable = mkEnableOption "Enable cloud backups";
  };

  config = mkIf cfg.enable {
    services.restic.backups.backblaze = {
      initialize = true;
      passwordFile = config.sops.secrets.restic_password.path;
      environmentFile = config.sops.secrets.restic_env.path;

      # TODO: use username here
      paths = ["/home/haseeb"];
      repository = "b2:Majiy00Backup";
      timerConfig = {
        OnUnitActiveSec = "1d";
      };
      exclude = [
        "~/.config/gtk"
      ];

      pruneOpts = [
        "--keep-weekly 5"
        "--keep-yearly 10"
      ];
    };

    sops.secrets.restic_password = {
      sopsFile = ../../secrets.yaml;
    };
    sops.secrets.restic_env = {
      sopsFile = ../../secrets.yaml;
    };
  };
}
