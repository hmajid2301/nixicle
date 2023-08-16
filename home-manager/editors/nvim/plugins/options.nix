{
  programs.nixvim = {
    globals = {
      mapleader = " ";
    };

    options = {
      termguicolors = true;
      scrolloff = 8;
      swapfile = false;
      hlsearch = false;
      incsearch = true;

      signcolumn = "yes";
      cmdheight = 2;
      cot = [ "menu" "menuone" "noselect" ];
      colorcolumn = "120";

      updatetime = 100;
      timeout = true;
      timeoutlen = 300;
    };
  };
}
