{ pkgs, config, ... }: {

  # sops.secrets.attic_auth_token = {
  #   sopsFile = ../secrets.yaml;
  # };

  #xdg.configFile."nix/netrc".source = config.sops.secrets.attic_auth_token.path;

  home.packages = with pkgs; [
    attic
  ];
}
