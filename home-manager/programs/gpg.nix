{ pkgs
, config
, ...
}:
{
  home.packages = [ pkgs.pinentry-gnome pkgs.gcr ];

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    enableExtraSocket = true;
    sshKeys = [ "F04F743A24CD81B628A20667CD20E7373D83B71C" ];
    pinentryFlavor = "gnome3";
  };

  programs = {
    gpg = {
      enable = true;
      publicKeys = [{ source = ../security/public.gpg; }];
    };
  };
}
