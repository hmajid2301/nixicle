{ ... }:
{
  den.aspects.zsh = {
    homeManager = { pkgs, ... }: {
      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
      };
    };
  };
}
