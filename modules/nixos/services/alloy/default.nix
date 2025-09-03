{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.nixicle.alloy;
in
{
  options.services.nixicle.alloy = {
    enable = mkEnableOption "Enable the alloy service";
  };

  config = mkIf cfg.enable {
    services = {
      alloy = {
        enable = true;
      };

      # cloudflared = {
      #   tunnels = {
      #     "0e845de6-544a-47f2-a1d5-c76be02ce153" = {
      #       ingress = {
      #         "alloy.haseebmajid.dev" = "http://localhost:12345";
      #       };
      #     };
      #   };
      # };
    };
  };
}
