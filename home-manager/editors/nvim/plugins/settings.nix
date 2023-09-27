{ pkgs, ... }: {
  programs.nixvim = {
    extraConfigLuaPre =
      ''
        require("neoconf").setup({})
      '';
    extraPlugins = with pkgs.vimPlugins; [
      neoconf-nvim
    ];
  };
}
