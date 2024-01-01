{
  services.blueman.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
    };
  };
}
