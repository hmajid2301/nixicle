{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.nixicle;
let
  cfg = config.roles.desktop.addons.greetd;

  defaultCommand =
    if config.roles.desktop.addons.niri.enable or false then
      "niri-session &> /dev/null"
    else if config.roles.desktop.addons.hyprland.enable or false then
      "Hyprland &> /dev/null"
    else if config.roles.desktop.addons.gnome.enable or false then
      "gnome-session"
    else
      "Hyprland &> /dev/null";

  greeterCommand = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${cfg.command}";
in
{
  options.roles.desktop.addons.greetd = with types; {
    enable = mkEnableOption "Enable login greeter";

    autologin = mkOption {
      type = bool;
      default = true;
      description = "Enable automatic login. When disabled, shows login screen instead.";
    };

    command =
      mkOpt str defaultCommand
        "Command to run on login. Auto-detected based on enabled window managers.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = mkIf (!cfg.autologin) [
      pkgs.tuigreet
    ];

    services.greetd = {
      enable = true;
      settings = rec {
        default_session = {
          command = if cfg.autologin then cfg.command else greeterCommand;
          user = if cfg.autologin then config.user.name else "greeter";
        };
        initial_session = mkIf cfg.autologin default_session;
      };
    };
  };
}
