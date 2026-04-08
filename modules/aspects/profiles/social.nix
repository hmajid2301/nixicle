{ den, ... }:
{
  den.aspects.social = {
    homeManager = { pkgs, ... }: {
      xdg.configFile."BetterDiscord/data/stable/custom.css" = {
        source = ./social/custom.css;
      };
      programs.discord = {
        enable = true;
        package = pkgs.goofcord;
      };
      home.packages = with pkgs; [
        shotwell
      ];
    };
  };
}
