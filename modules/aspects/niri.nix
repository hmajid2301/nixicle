{ den, ... }:
{
  den.aspects.niri = {
    includes = [
      ({ host, user, ... }: {
        nixos = { config, pkgs, lib, ... }: {
          services.greetd = {
            enable = true;
            useTextGreeter = !host.autologin;
            settings =
              let
                session = {
                  command = "niri-session &> /dev/null";
                  user = user.userName;
                };
                greeterSession = {
                  command =
                    let
                      theme = with config.lib.stylix.colors.withHashtag; "border=${base0D};text=${base05};prompt=${base0E};time=${base04};action=${base0B};button=${base0C};container=${base00};input=${base02}";
                    in
                    "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd 'niri-session &> /dev/null' --theme '${theme}'";
                  user = "greeter";
                };
              in
              {
                default_session = if host.autologin then session else greeterSession;
              }
              // lib.optionalAttrs host.autologin { initial_session = session; };
          };

          environment.persistence."/persist" = lib.mkIf config.system.impermanence.enable {
            directories = [ "/var/cache/tuigreet" ];
          };
        };
      })
    ];

    nixos = { config, pkgs, lib, ... }: {
      nix.settings = {
        substituters = [ "https://niri.cachix.org" ];
        trusted-public-keys = [ "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=" ];
      };

      programs.niri.enable = true;
      programs.xwayland.enable = true;

      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = with pkgs; [
        wl-clipboard
        slurp
        grim
        wf-recorder
        brightnessctl
        ffmpegthumbnailer
        gst_all_1.gst-libav
        gdk-pixbuf
        webp-pixbuf-loader
        nautilus-open-any-terminal
        nautilus-python
        gvfs
        nfs-utils
        # evolution-data-server deps
        gnome-online-accounts
        python3
      ];
      environment.pathsToLink = [ "/share/nautilus-python/extensions" ];
      environment.variables = {
        NAUTILUS_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";
        NAUTILUS_4_EXTENSION_DIR = "${config.system.path}/lib/nautilus/extensions-4";
        GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
          with pkgs.gst_all_1;
          [
            gst-plugins-good
            gst-plugins-bad
            gst-plugins-ugly
            gst-libav
          ]
        );
      };

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-gnome
        ];
        config.niri = {
          default = [ "gnome" "gtk" ];
          "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
          "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        };
        xdgOpenUsePortal = true;
      };

      # polkit-gnome authentication agent
      security.polkit.enable = true;
      systemd.user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };

      # evolution-data-server for calendar/contacts
      services.gnome.evolution-data-server.enable = true;
      programs.dconf.enable = true;
      services.gvfs.enable = true;
      services.udisks2.enable = true;
    };

  };
}
