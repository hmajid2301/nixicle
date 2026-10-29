_: {
  den.aspects.worktrunk = {
    homeManager =
      { pkgs, lib, ... }:
      {
        programs.worktrunk = {
          enable = true;
          package = pkgs.worktrunk;
          enableFishIntegration = false;
          settings.worktree-path = "~/worktrees/{{ repo }}/{{ branch | sanitize }}";
        };

        programs.fish.interactiveShellInit = ''
          source ${
            pkgs.runCommand "worktrunk-init.fish" { } ''
              ${lib.getExe pkgs.worktrunk} config shell init fish > $out
            ''
          }
        '';
      };
  };
}
