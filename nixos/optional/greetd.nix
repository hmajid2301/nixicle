{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.nixos.login;
in {
  options.modules.nixos.login = {
    enable = mkEnableOption "Enable login greeter";
  };

  config = mkIf cfg.enable {
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

    environment.etc."greetd/environments".text = ''
      Hyprland
    '';
  };
}
