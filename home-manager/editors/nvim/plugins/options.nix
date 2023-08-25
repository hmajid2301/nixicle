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
      tabstop = 4;
      softtabstop = 4;
      expandtab = true;
      smartindent = true;

      cursorline = true;
      number = true;
      relativenumber = true;
      numberwidth = 2;
      ruler = false;

      signcolumn = "yes";
      cmdheight = 2;
      cot = ["menu" "menuone" "noselect"];
      colorcolumn = "120";

      updatetime = 100;
      timeout = true;
      timeoutlen = 250;

      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
    };
  };
}
