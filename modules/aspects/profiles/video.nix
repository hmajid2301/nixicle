{ den, ... }:
{
  den.aspects.video = {
    includes = [ den.aspects.obs ];

    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        audacity
        davinci-resolve-studio
      ];
    };
  };
}
