{ den, ... }:
{
  den.aspects.haseeb.provides.framework = {
    includes = [
      den.aspects.desktop
      den.aspects.gaming
      den.aspects.social

      ({ host, ... }: {
        homeManager = { ... }: {
          desktops.addons.swayidle = {
            enable = host.isLaptop;
            timeouts = {
              lock = 300;
              dpms = 330;
              suspend = 0;
              hibernate = 900;
            };
          };
        };
      })
    ];

    homeManager = { ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "24.05";
      };

      desktops = {
        niri.enable = true;
        addons.noctalia = {
          enable = true;
          laptop = true;
          settings.osd.monitors = [ "eDP-1" ];
        };
      };
    };
  };
}
