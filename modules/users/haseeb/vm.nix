{ den, ... }:
{
  den.aspects.haseeb.provides.vm = {
    homeManager = { ... }: {
      home = {
        username = "haseeb";
        homeDirectory = "/home/haseeb";
        stateVersion = "23.11";
      };

      desktops.niri.enable = true;

      roles = {
        desktop.enable = true;
        gaming.enable = true;
      };

      cli.tools.ssh.enableKeychain = false;
    };
  };
}
