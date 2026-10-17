_: {
  den.aspects.worktrunk = {
    homeManager =
      { pkgs, ... }:
      {
        programs.worktrunk = {
          enable = true;
          package = pkgs.worktrunk;
          enableFishIntegration = true;
          settings.worktree-path = "~/worktrees/{{ repo }}/{{ branch | sanitize }}";
        };
      };
  };
}
