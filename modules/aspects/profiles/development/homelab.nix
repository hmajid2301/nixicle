{ ... }:
{
  den.aspects.devHomelab = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        openbao
        kind
        kaf
      ];
    };
  };
}
