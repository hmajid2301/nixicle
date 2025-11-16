{
  roles = {
    desktop.enable = true;
    gaming.enable = true;
  };

  nixicle.user = {
    enable = true;
    name = "haseeb";
  };

  # Disable keychain for VM to avoid SSH key errors on fresh installs
  cli.tools.ssh.enableKeychain = false;

  home.stateVersion = "23.11";
}
