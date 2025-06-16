{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.atuin;
in
{
  options.services.nixicle.atuin = {
    enable = mkEnableOption "Enable atuin";
  };

  config = mkIf cfg.enable {
    services = {
      atuin = {
        enable = true;
        openRegistration = true;
        maxHistoryLength = 99999999;
      };

      # cloudflared = {
      #   tunnels = {
      #     "0e845de6-544a-47f2-a1d5-c76be02ce153" = {
      #       ingress = {
      #         "atuin.haseebmajid.dev" = "http://localhost:8888";
      #       };
      #     };
      #   };
      # };
    };
  };
}
