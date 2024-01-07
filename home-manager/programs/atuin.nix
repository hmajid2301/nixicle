{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.atuin-export-fish];

  programs.atuin = {
    enable = true;
    flags = [
      "--disable-up-arrow"
    ];
    settings = {
      sync_address = "https://majiy00-shell.fly.dev";
      sync_frequency = "15m";
      dialect = "uk";
      enter_accept = false;
      # key_path = config.sops.secrets.atuin_key.path;
    };
  };

  sops.secrets.atuin_key = {
    sopsFile = ../secrets.yaml;
  };
}
