{
  services = {
    fprintd = {
      enable = true;
    };
  };

  security.pam.services = {
    swaylock.fprintAuth = true;
    login.fprintAuth = true;
    sudo.fprintAuth = true;
  };
}
