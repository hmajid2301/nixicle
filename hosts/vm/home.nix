{
  desktops.niri = {
    enable = true;
  };

  desktops.addons = {
    noctalia.enable = true;
    rofi.enable = true;
  };

  roles = {
    desktop.enable = true;
    gaming.enable = true;
  };

  nixicle.user = {
    enable = true;
    name = "haseeb";
  };

  cli.tools.ssh.enableKeychain = false;

  home.stateVersion = "23.11";
}
