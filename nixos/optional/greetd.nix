{ inputs, pkgs, config, ... }: {
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

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  environment.etc."greetd/environments".text = ''
    Hyprland
  '';
}
