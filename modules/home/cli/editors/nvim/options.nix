{
  programs.nixvim = {
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    opts = {
      sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions";
      switchbuf = "useopen,uselast";
      termguicolors = true;
      scrolloff = 8;
      ignorecase = true;
      smartcase = true;

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

      splitbelow = true;
      splitright = true;
      undofile = true;
      undolevels = 10000;

      signcolumn = "yes";
      cmdheight = 1;
      cot = ["menu" "menuone" "noselect"];
      colorcolumn = "120";

      updatetime = 100;
      timeout = true;
      timeoutlen = 1000;

      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;

      winwidth = 10;
      winminwidth = 10;
      equalalways = false;
    };
  };
}
