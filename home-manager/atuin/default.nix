{ config, ... }: {
  programs.atuin = {
    enable = true;
    settings = {
      sync_address = "https://majiy00-shell.fly.dev";
      sync_frequency = "15m";
      dialect = "uk";
      #key_path = config.sops.secrets.atuin_key.path;
    };
  };

  sops.secrets.atuin_key = {
    sopsFile = ../secrets.yaml;
  };
}

