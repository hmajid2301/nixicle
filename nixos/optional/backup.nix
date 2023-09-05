{ config
, pkgs
, ...
}: {
  environment.systemPackages = [ pkgs.restic ];

  services.restic.backups.backblaze = {
    initialize = true;
    passwordFile = config.sops.secrets.restic_password.path;
    environmentFile = config.sops.secrets.restic_env.path;

    paths = [ "/home/haseeb" ];
    repository = "b2:Majiy00Backup";
    timerConfig = {
      OnUnitActiveSec = "1d";
    };
    exclude = [
      "/home/haseeb/Games"
      "~/.config/gtk"
      "~/.local/steam"
    ];

    pruneOpts = [
      "--keep-weekly 5"
      "--keep-yearly 10"
    ];
  };

  sops.secrets.restic_password = {
    sopsFile = ../secrets.yaml;
  };
  sops.secrets.restic_env = {
    sopsFile = ../secrets.yaml;
  };
}
