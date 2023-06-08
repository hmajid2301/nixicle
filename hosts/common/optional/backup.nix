{ config, pkgs, ... }:
{
  environment.systemPackages = [ pkgs.restic ];

  services.restic.backups.myaccount = {
    initialize = true;
    # since this uses an `agenix` secret that's only readable to the
    # root user, we need to run this script as root. If your
    # environment is configured differently, you may be able to do:
    #
    # user = "myuser
    #
    passwordFile = "/etc/nixos/secrets/restic-password";
    environmentFile = "/etc/nixos/secrets/restic-env";
    # what to backup.
    paths = ["/home/haseeb"];
    # the name of your repository.
    repository = "b2:Majiy00Backup";
    timerConfig = {
      # backup every 1d
      OnUnitActiveSec = "7d";
    };


    # keep 7 daily, 5 weekly, and 10 annual backups
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 5"
      "--keep-yearly 10"
    ];
  };

  # Instead of doing this, you may alternatively hijack the
  # `awsS3Credentials` argument to pass along these environment
  # vars.
  #
  # If you specified a user above, you need to change it to:
  # systemd.services.user.restic-backups-myaccount = { ... }
  #
  systemd.services.restic-backups-myaccount = {
  };

}

