{ pkgs, config, ... }: {
  networking.wireguard.enable = true;

  services.mullvad-vpn = {
    enable = true;
  };

  environment.systemPackages = [ pkgs.mullvad-vpn pkgs.mullvad ];

  sops.secrets.mullvad_account_id = {
    sopsFile = ../secrets.yaml;
  };

  #TODO: fix this
  # systemd.services."mullvad-daemon" = {
  #   serviceConfig.LoadCredential = [ "account:${config.sops.secrets.mullvad_account_id.path}" ];
  #   postStart =
  #     ''
  #       while ! ${pkgs.mullvad}/bin/mullvad status >/dev/null; do sleep 1; done
  #       ${pkgs.mullvad}/bin/mullvad auto-connect set on
  #       ${pkgs.mullvad}/bin/mullvad tunnel ipv6 set on
  #       ${pkgs.mullvad}/bin/mullvad set default \
  #           --block-ads --block-trackers --block-malware
  #     '';
  # };
}
