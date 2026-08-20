{ ... }:
{
  den.aspects.devJs = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        nodejs_24
        bun
        pnpm
        ast-grep
      ];
    };
  };
}
