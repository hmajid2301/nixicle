{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.nixicle.home-assistant;
in {
  options.services.nixicle.home-assistant = {
    enable = mkEnableOption "Enable home assistant";
  };

  config = mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      openFirewall = true;
      extraComponents = [
        "esphome"
        "met"
        "radio_browser"
      ];
      extraPackages = python3Packages:
        with python3Packages; [
          bellows
          numpy
          aiodhcpwatcher
          aiodiscover
          gtts
          zigpy-zigate
          universal-silabs-flasher
          zha-quirks
          zigpy-deconz
          zigpy-xbee
          zigpy-znp
          zigpy-cc
        ];
      config = {
        http = {
          server_port = 8123;
          use_x_forwarded_for = true;
          trusted_proxies = ["127.0.0.1" "::1"];
        };
        zha = {
          usb_path = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_94923f9c55a4ed11abf188582981d5c7-if00-port0";
        };
      };
    };
  };
}
