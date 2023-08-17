{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [persistence-nvim];

    plugins.auto-save = {
      enable = true;
    };
  };
}
