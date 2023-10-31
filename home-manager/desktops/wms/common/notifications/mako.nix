{ config
, pkgs
, lib
, ...
}:
with lib;
let
  cfg = config.modules.wms.notifications.mako;
in
{
  options.modules.wms.notifications.mako = {
    enable = mkEnableOption "enable mako notification manager";
  };

  config = mkIf cfg.enable {
    services.mako = {
      enable = true;
      defaultTimeout = 5000;
      backgroundColor = "#${config.colorscheme.colors.base00}";
      textColor = "#${config.colorscheme.colors.base05}";
      borderColor = "#${config.colorscheme.colors.base0D}";
      progressColor = "over #${config.colorscheme.colors.base02}";
      extraConfig = ''
        [urgency=high]
        border-color=#${config.colorscheme.colors.base09}
      '';
    };

    home.packages = with pkgs; [
      libnotify
    ];
  };
}
