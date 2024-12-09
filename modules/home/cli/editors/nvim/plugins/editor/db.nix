{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-dbee
    ];

    extraConfigLua = ''
      require("dbee").setup()
    '';
  };
}
