{
  pkgs,
  config,
  ...
}: {
  networking.wireguard.enable = true;
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  sops.secrets.mullvad_account_id = {
    sopsFile = ../secrets.yaml;
  };

  systemd.services."mullvad-daemon" = {
    serviceConfig.LoadCredential = ["account:${config.sops.secrets.mullvad_account_id.path}"];

    postStart = ''
      while ! ${pkgs.mullvad}/bin/mullvad status >/dev/null; do sleep 1; done
      ${pkgs.mullvad}/bin/mullvad auto-connect set on
      ${pkgs.mullvad}/bin/mullvad tunnel set ipv6 on
      ${pkgs.mullvad}/bin/mullvad dns set default --block-ads --block-trackers --block-malware
      ${pkgs.mullvad}/bin/mullvad lan set allow
      ${pkgs.mullvad}/bin/mullvad split-tunnel add $(${pkgs.procps}/bin/pgrep tailscaled)
    '';
  };
}
