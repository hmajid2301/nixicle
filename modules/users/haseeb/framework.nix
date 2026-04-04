{ den, ... }:
{
  # Per-host user config for haseeb on framework.
  # Applied via mutual-provider when den evaluates the {host=framework, user=haseeb} context.
  den.aspects.haseeb.provides.framework = {
    homeManager = { ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "24.05";
      };

      roles = {
        desktop.enable = true;
        development.enable = true;
        gaming.enable = true;
        social.enable = true;
      };

      desktops = {
        niri.enable = true;
        addons = {
          noctalia = {
            enable = true;
            laptop = true;
            settings.osd.monitors = [ "eDP-1" ];
          };
          swayidle = {
            enable = true;
            timeouts = {
              lock = 300;
              dpms = 330;
              suspend = 0;
              hibernate = 900;
            };
          };
        };
      };
    };
  };
}
