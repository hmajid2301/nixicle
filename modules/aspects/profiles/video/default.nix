{ den, ... }:
{
  den.aspects.video = {
    includes = [
      den.aspects.obs
      (den.batteries.unfree [ "davinci-resolve-studio" ])
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          audacity
          davinci-resolve-studio
        ];
      };
  };
}
