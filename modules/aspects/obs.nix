{ den, inputs, ... }:
{
  flake-file.inputs.catppuccin-obs = {
    url = "github:catppuccin/obs";
    flake = false;
  };

  den.aspects.obs = {
    homeManager = { inputs, ... }: {
      xdg.configFile."obs-studio/themes".source = "${inputs.catppuccin-obs}/themes";
      programs.obs-studio.enable = true;
    };
  };
}
