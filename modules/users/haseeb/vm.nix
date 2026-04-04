{ den, ... }:
{
  den.aspects.haseeb.provides.vm = {
    includes = [
      den.aspects.desktop
      den.aspects.gaming
    ];

    homeManager = { ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "23.11";
      };

      desktops.niri.enable = true;

      cli.tools.ssh.enableKeychain = false;
    };
  };
}
