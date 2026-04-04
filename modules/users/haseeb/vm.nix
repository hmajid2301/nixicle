{ den, ... }:
{
  # Per-host user config for haseeb on vm.
  # Applied via mutual-provider when den evaluates the {host=vm, user=haseeb} context.
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
