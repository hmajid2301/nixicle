_: {
  den.aspects.zsh = {
    homeManager =
      { config, ... }:
      {
        programs.zsh = {
          enable = true;
          autosuggestion.enable = true;
          dotDir = "${config.xdg.configHome}/zsh";
        };
      };
  };
}
