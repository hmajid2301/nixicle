{ ... }:
{
  den.aspects.attic = {
    homeManager =
      { pkgs, config, ... }:
      {
        sops.secrets.netrc = {
          sopsFile = ../secrets.yaml;
        };

        home.packages = [ pkgs.attic-client ];

        nix.settings.netrc-file = config.sops.secrets."netrc".path;

        systemd.user.services.attic-watch-store = {
          Unit = {
            Description = "Watch Nix Store and push to Attic cache";
            After = [ "graphical-session.target" ];
            Requires = [ "graphical-session.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${pkgs.attic-client}/bin/attic watch-store --jobs 10 main";
            Restart = "on-failure";
            RestartSec = "5";
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      };
  };
}
