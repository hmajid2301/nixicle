{ den, ... }:
{
  den.aspects.haseeb.provides.framebox = {
    includes = [
      den.aspects.desktop
      den.aspects.gaming
      den.aspects.social
      den.aspects.video
    ];

    homeManager = { ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "24.05";
      };

      desktops = {
        niri.enable = true;
        addons = {
          noctalia.enable = true;
          swayidle = {
            enable = true;
            timeouts = {
              lock = 300;
              dpms = 330;
              suspend = 0;
              hibernate = 0;
            };
          };
        };
      };
    };
  };
}
