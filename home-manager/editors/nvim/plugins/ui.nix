{pkgs, ...}: {
  imports = [
    ./ui/lualine.nix
  ];

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-web-devicons
    ];
  };
}
