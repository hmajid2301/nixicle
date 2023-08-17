{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [tmux-nvim];
    extraConfigLua =
      # lua
      ''
        function() return require("tmux").setup()
      '';
  };
}
