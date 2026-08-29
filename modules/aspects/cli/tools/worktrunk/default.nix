{ inputs, ... }:
{
  flake-file.inputs.worktrunk = {
    url = "github:max-sixty/worktrunk";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.worktrunk = {
    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.worktrunk.homeModules.default ];

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
