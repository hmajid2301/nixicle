{ config, ... }: {
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "Hyprland";
        user = "haseeb";
      };
      default_session = initial_session;
    };
  };

  # TODO: use config here
  environment.etc."greetd/environments".text = ''
    		Hyprland
  '';
}
