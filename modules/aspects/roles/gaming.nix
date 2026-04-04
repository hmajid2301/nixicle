{ den, ... }:
{
  den.aspects.gaming = {
    homeManager = { pkgs, ... }: {
      programs.mangohud = {
        enable = false;
        enableSessionWide = true;
        settings.cpu_load_change = true;
      };
      home.packages = with pkgs; [
        lutris
        bottles
      ];
    };
  };
}
