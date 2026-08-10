{ ... }:
{
  den.aspects.devDb = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        dbeaver-bin
        termdbms
        pgcli
      ];
    };
  };
}
