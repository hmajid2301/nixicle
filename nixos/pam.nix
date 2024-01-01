{
  security.pam.services = {
    swaylock = {
      u2fAuth = true;
    };

    login = {
      u2fAuth = true;
    };

    sudo = {
      u2fAuth = true;
    };
  };
}
