_: {
  den.aspects.social = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          shotwell
        ];
      };
  };
}
