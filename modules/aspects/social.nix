# social aspect — replaces roles.social.enable = true (home-manager only).
{ den, ... }:
{
  den.aspects.social = {
    homeManager = { pkgs, ... }: {
      xdg.configFile."BetterDiscord/data/stable/custom.css" = {
        source = ../home/roles/social/custom.css;
      };

      programs.discord = {
        enable = true;
        package = pkgs.goofcord;
      };

      home.packages = with pkgs; [ shotwell ];
    };
  };
}
