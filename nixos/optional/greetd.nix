{ pkgs, ... }: {
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd  Hyprland";
        user = "haseeb";
      };
      default_session = initial_session;
    };
  };
  environment.etc."greetd/environments".text = ''
    Hyprland
  '';
}
