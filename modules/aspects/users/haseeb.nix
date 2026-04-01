# haseeb user aspect — extends den.aspects.haseeb (auto-created for all hosts).
# Uses den.provides.* for user/shell setup, and per-host provides for differences.
{ den, ... }:
{
  den.aspects.haseeb = {
    includes = [
      den.provides.primary-user
      (den.provides.user-shell "fish")
      den.aspects.development
      den.aspects.social
    ];

    # homeManager config that applies on every host
    homeManager = { ... }: {
      gtk.gtk4.theme = null;
      programs.git.signing = {
        format = "ssh";
        signByDefault = true;
      };
    };

    # Per-host home-manager config via provides — the dendritic way.
    # Each key matches a host name; den.provides.mutual-provider resolves it.
    provides = {
      # framework-specific: laptop noctalia, swayidle with hibernate
      framework.homeManager = { ... }: {
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
              timeouts = { lock = 300; dpms = 330; suspend = 0; hibernate = 900; };
            };
          };
        };
        roles.video.enable = true;
      };

      # framebox-specific: desktop noctalia, swayidle without hibernate, video role
      framebox.homeManager = { ... }: {
        desktops = {
          niri.enable = true;
          addons = {
            noctalia.enable = true;
            swayidle = {
              enable = true;
              timeouts = { lock = 300; dpms = 330; suspend = 0; hibernate = 0; };
            };
          };
        };
        roles.video.enable = true;
      };

      # workstation-specific: same as framebox
      workstation.homeManager = { ... }: {
        desktops = {
          niri.enable = true;
          addons = {
            noctalia.enable = true;
            swayidle = {
              enable = true;
              timeouts = { lock = 300; dpms = 330; suspend = 0; hibernate = 0; };
            };
          };
        };
        roles.video.enable = true;
      };

      # vm-specific: minimal, no swayidle, ssh keychain off
      vm.homeManager = { ... }: {
        desktops.niri.enable = true;
        cli.tools.ssh.enableKeychain = false;
        home.stateVersion = "23.11";
      };
    };
  };

  # Enable mutual-provider so the per-host provides above are resolved
  den.ctx.user.includes = [ den.provides.mutual-provider ];
}
