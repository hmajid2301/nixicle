{
  den,
  ...
}:
{
  den.aspects.kitchenSink = {
    includes = [
      den.aspects.tmux
      den.aspects.zsh
      den.aspects.kitty
      den.aspects.alacritty
      den.aspects.wezterm
      den.aspects.kubernetesCli
      den.aspects.bitwarden
      den.aspects.server-console
    ];
  };
}
