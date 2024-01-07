{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.nixos.vpn;
in {
  options.modules.nixos.vpn = {
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
      sopsFile = ../secrets.yaml;
    };

    systemd.services."mullvad-daemon" = {
      serviceConfig.LoadCredential = ["account:${config.sops.secrets.mullvad_account_id.path}"];

      postStart = ''
        #    while ! ${pkgs.mullvad}/bin/mullvad status >/dev/null; do sleep 1; done
        #    ${pkgs.mullvad}/bin/mullvad auto-connect set on
        #    ${pkgs.mullvad}/bin/mullvad tunnel set ipv6 on
        #    ${pkgs.mullvad}/bin/mullvad dns set default --block-ads --block-trackers --block-malware
        #    ${pkgs.mullvad}/bin/mullvad lan set allow
        #    ${pkgs.mullvad}/bin/mullvad split-tunnel add $(${pkgs.procps}/bin/pgrep tailscaled)
        #
        # account="$(<"$CREDENTIALS_DIRECTORY/account")"
        # current_account="$(${pkgs.mullvad}/bin/mullvad account get | grep "account:" | sed 's/.* //')"
        # if [[ "$current_account" != "$account" ]]; then
        # 	${pkgs.mullvad}/bin/mullvad account login "$account"
        # fi
      '';
    };
  };
}
