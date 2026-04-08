{ den, ... }:
{
  den.aspects.gpg = {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.seahorse ];

      services.gnome-keyring.enable = true;

      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        enableExtraSocket = true;
        sshKeys = [ "D528D50F4E9F031AACB1F7A9833E49C848D6C90" ];
        pinentry.package = pkgs.pinentry-gnome3;
      };

      programs.gpg.enable = true;
    };
  };
}
