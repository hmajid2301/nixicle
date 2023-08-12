{
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "Hyprland";
        user = "haseeb";
      };
      default_session = {
        command = "initial_session";
      };
    };
  };
  environment.etc."greetd/environments".text = ''
    Hyprland
  '';
}
