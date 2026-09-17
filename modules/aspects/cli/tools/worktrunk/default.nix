_: {
  den.aspects.worktrunk = {
    homeManager =
      { pkgs, ... }:
      {
        programs.worktrunk = {
          enable = true;
          package = pkgs.worktrunk;
          enableFishIntegration = true;
        };

        xdg.configFile."worktrunk/config.toml".text = ''
          worktree-path = "~/worktrees/{{ repo }}/{{ branch | sanitize }}"
        '';
      };
  };
}
