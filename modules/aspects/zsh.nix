_: {
  den.aspects.zsh = {
    homeManager =
      { ... }:
      {
        programs.zsh = {
          enable = true;
          autosuggestion.enable = true;
        };
      };
  };
}
