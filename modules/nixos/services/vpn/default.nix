{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.vpn;
in {
  options.services.vpn = {
    enable = mkEnableOption "Enable vpn";
  };

  config = mkIf cfg.enable {
    networking.wireguard.enable = true;
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };
    services.tailscale.enable = true;

    sops.secrets.mullvad_account_id = {
      sopsFile = ../../secrets.yaml;
    };
  };
}
