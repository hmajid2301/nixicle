_: {
  den.aspects.gpg = {
    nixos = { pkgs, ... }: {
      services.dbus.packages = [ pkgs.gcr_4 ];
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.seahorse ];

        services.gnome-keyring.enable = true;

        services.gpg-agent = {
          enable = true;
          enableExtraSocket = true;
          pinentry.package = pkgs.pinentry-gnome3;
        };

        programs.gpg.enable = true;
      };
  };
}
