{ den, ... }:
{
  den.aspects.home-assistant = {
    nixos = { pkgs, lib, ... }: {
      services = {
        home-assistant = {
          enable = true;
          openFirewall = true;
          extraComponents = [
            "esphome" "met" "radio_browser" "prometheus"
            "recorder" "default_config" "history" "history_stats"
          ];
          customComponents = with pkgs.home-assistant-custom-components; with pkgs.nixicle; [
            octopus-energy
          ];
          extraPackages = python3Packages: with python3Packages; [
            bellows numpy aiodhcpwatcher aiodiscover gtts psycopg2
            universal-silabs-flasher zha-quirks zigpy-cc zigpy-deconz
            zigpy-xbee zigpy-znp zigpy-zigate pydantic
          ];
          config = {
            recorder.db_url = "postgresql://@/hass";
            history = { };
            default_config = { };
            prometheus = { };
            http = {
              server_port = 8123;
              use_x_forwarded_for = true;
              trusted_proxies = [ "127.0.0.1" "::1" ];
            };
            zha.usb_path = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_94923f9c55a4ed11abf188582981d5c7-if00-port0";
          };
        };

        postgresql = {
          ensureDatabases = [ "hass" ];
          ensureUsers = [ { name = "hass"; ensureDBOwnership = true; } ];
        };

        traefik.dynamicConfigOptions.http = lib.nixicle.mkTraefikService {
          name = "homeAssistant";
          port = 8123;
          subdomain = "home-assistant";
        };
      };
    };
  };
}
