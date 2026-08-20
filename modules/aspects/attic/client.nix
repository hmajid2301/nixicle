# Home-manager attic client: installs `attic-client` and a user `watch-store`
# service that pushes newly-built store paths to the `main` cache. Use this on
# dev/desktop profiles where you actually build and publish packages; servers
# that only pull substitutes should use `den.aspects.attic-cache` instead.
{ ... }:
{
  den.aspects.attic-client = {
    homeManager =
      { pkgs, config, ... }:
      {
        sops.secrets.netrc = {
          sopsFile = ../../secrets.yaml;
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
