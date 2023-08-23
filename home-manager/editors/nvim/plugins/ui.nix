{pkgs, ...}: {
  imports = [
    ./ui/nvim-tree.nix
    ./ui/lualine.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-web-devicons
    ];
  };
}
