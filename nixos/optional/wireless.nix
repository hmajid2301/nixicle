{
  config,
  lib,
  ...
}: {
  # Wireless secrets stored through sops
  sops.secrets.home_wireless_password = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };

  networking.wireless = {
    enable = true;
    fallbackToWPA2 = false;
    networks = {
      "SKYFQFHK" = {
        psk = config.sops.secrets.home_wireless_password.path;
      };
    };

    # Imperative
    allowAuxiliaryImperativeNetworks = true;
    userControlled = {
      enable = true;
      group = "network";
    };
    extraConfig = ''
      update_config=1
    '';
  };

  # Ensure group exists
  users.groups.network = {};
}
