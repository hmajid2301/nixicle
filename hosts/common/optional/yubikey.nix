{ pkgs, ... }: {
  services = {
    pcscd.enable = true;
    udev.packages = with pkgs; [
      libu2f-host
      yubikey-personalization
    ];
  };

  environment.systemPackages = with pkgs; [ 
    yubikey-manager-qt
    yubioath-flutter
  ];
}

