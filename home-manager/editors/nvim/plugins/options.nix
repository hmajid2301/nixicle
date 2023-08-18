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

      shiftwidth = 4;
      expandtab = true;
      smartindent = true;
      tabstop = 4;
      softtabstop = 4;

      number = true;
      numberwidth = 2;
      ruler = false;

      signcolumn = "yes";
      cmdheight = 2;
      cot = ["menu" "menuone" "noselect"];
      colorcolumn = "120";

      updatetime = 100;
      timeout = true;
      timeoutlen = 300;
    };
  };
}
