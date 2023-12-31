{pkgs, ...}: {
  networking.wireguard.enable = true;
  services.mullvad-vpn.enable = true;

  environment.systemPackages = with pkgs; [
    mullvad-vpn
    mullvad
  ];

  sops.secrets.mullvad_account_id = {
    sopsFile = ../secrets.yaml;
  };

  systemd.services."mullvad-daemon".postStart = ''
    while ! ${pkgs.mullvad}/bin/mullvad status >/dev/null; do sleep 1; done
    # ${pkgs.mullvad}/bin/mullvad auto-connect set on
    # ${pkgs.mullvad}/bin/mullvad dns set default
    # ${pkgs.mullvad}/bin/mullvad lan set allow
    # ${pkgs.mullvad}/bin/mullvad tunnel set ipv6 on
    # ${pkgs.mullvad}/bin/mullvad tunnel set wireguard --quantum-resistant=on
    # ${pkgs.mullvad}/bin/mullvad relay set tunnel-protocol wireguard
    ${pkgs.mullvad}/bin/mullvad split-tunnel add $(${pkgs.procps}/bin/pgrep tailscaled)
  '';
}
