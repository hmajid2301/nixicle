{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ tmux-nvim ];
    extraConfigLua =
      # lua
      ''
        require("tmux").setup()
      '';
  };
}
