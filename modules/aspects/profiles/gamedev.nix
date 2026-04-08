{ den, ... }:
{
  den.aspects.gamedev = {
    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        godot_4
        aseprite
      ];
    };
  };
}
