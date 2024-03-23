{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.suites.development;
in {
  options.suites.development = {
    enable = mkEnableOption "Enable development configuration";
  };

  config = mkIf cfg.enable {
    suites.common.enable = true;

    cli = {
      editors.nvim.enable = true;
      multiplexers.zellij.enable = true;
      scripts.enable = true;

      programs = {
        atuin.enable = true;
        bat.enable = true;
        bottom.enable = true;
        direnv.enable = true;
        eza.enable = true;
        fzf.enable = true;
        git.enable = true;
        gpg.enable = true;
        k8s.enable = true;
        modern-unix.enable = true;
        network-tools.enable = true;
        nix-index.enable = true;
        podman.enable = true;
        ssh.enable = true;
        starship.enable = true;
        yazi.enable = true;
        zoxide.enable = true;
      };
    };
  };
}
