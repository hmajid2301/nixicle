{ pkgs, ... }: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [ nvim-web-devicons nvchad-ui ];
  };
}
