{ den, ... }:
{
  flake-file.inputs.catppuccin-obs = {
    url = "github:catppuccin/obs";
    flake = false;
  };

  den.aspects.video = {
    homeManager = { pkgs, inputs, ... }: {
      xdg.configFile."obs-studio/themes".source = "${inputs.catppuccin-obs}/themes";

      programs.obs-studio.enable = true;

      home.packages = with pkgs; [
        audacity
        davinci-resolve-studio
      ];
    };
  };
}
