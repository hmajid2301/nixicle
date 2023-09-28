{ config, ... }: {
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = (
          if config.home-manager.users.haseeb.wayland.windowManager.sway.enable
          then "sway"
          else "Hyprland"
        );
        user = "haseeb";
      };
      default_session = initial_session;
    };
  };
  environment.etc."greetd/environments".text = ''
        Hyprland
    		sway
  '';
}
