{ pkgs, ... }: {
  # TODO: add new value
  # xdg.configFile."Yubico/u2f_keys" = {
  #   text = "haseeb:cv4DGZDXrn2IdYa58Km8My8DJzg/UTgDhz1L8o2VZeb0o0e2NAQHDsiLNoMv1klA7tpzh2ya464VpCRxnqDHSg==,kjbw2RoP/WLjg2Fmwrnjfv27oxhAqMzVBb+cmHYTL5VXvUrhXj1D4P6Ga0HcaE5xeAXSCZviD9eolyxEN2SlqQ==,es256,+presence";
  # };

  home.packages = with pkgs; [
    yubico-piv-tool
    #yubioath-flutter
  ];
}
