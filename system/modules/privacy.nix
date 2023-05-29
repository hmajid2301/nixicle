{ config, pkgs, ... }:

{
  virtualisation = {
    oci-containers = {
      backend = "docker";
      containers.whoogle-search = {
        image = "benbusby/whoogle-search";
        autoStart = true;
        ports = [ "5000:5000" ];
      };
    };
  };
}





