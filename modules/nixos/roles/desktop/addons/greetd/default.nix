{
  config,
  lib,
  mkOpt ? null,
  ...
}:
with lib; 
let
  cfg = config.roles.desktop.addons.greetd;
  
  # Auto-detect which window manager is enabled
  # Priority: niri > hyprland > gnome
  defaultCommand = 
    if config.roles.desktop.addons.niri.enable or false then
      "niri-session &> /dev/null"
    else if config.roles.desktop.addons.hyprland.enable or false then
      "Hyprland &> /dev/null"
    else if config.roles.desktop.addons.gnome.enable or false then
      "gnome-session"
    else
      "Hyprland &> /dev/null";  # Fallback to Hyprland
in {
  options.roles.desktop.addons.greetd = with types; {
    enable = mkEnableOption "Enable login greeter";
    
    command = mkOpt str defaultCommand "Command to run on login. Auto-detected based on enabled window managers.";
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = rec {
        default_session = {
          command = cfg.command;
          user = config.user.name;
        };
        initial_session = default_session;
      };
    };
  };
}
