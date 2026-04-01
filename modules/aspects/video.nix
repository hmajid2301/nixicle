# video aspect — replaces roles.video.enable = true (home-manager only).
{ den, ... }:
{
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
