{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      twilight-nvim
      zen-mode-nvim
    ];

    extraConfigLua = ''
      require("twilight").setup()
      require("zen-mode").setup({
      	options = {
      		 signcolumn = "no", -- disable signcolumn
      		 number = false, -- disable number column
      		 relativenumber = false, -- disable relative numbers
      		 cursorline = false, -- disable cursorline
      		 cursorcolumn = false, -- disable cursor column
      		 foldcolumn = "0", -- disable fold column
      		 list = false, -- disable whitespace characters
      	},
      	plugins = {
      		options = {
      			enabled = true,
      			ruler = false, -- disables the ruler text in the cmd line area
      			showcmd = false, -- disables the command in the last line of the screen
      			laststatus = 0, -- turn off the statusline in zen mode
      		},
      		wezterm = {
      			enabled = true,
      			font = "+4",
      		},
      	},
      	on_open = function(win)
      		 require("barbecue.ui").toggle(false)
      		 vim.wo.relativenumber = false
      		 vim.wo.number = false
      	end,
      	on_close = function()
      		 require("barbecue.ui").toggle(true)
      		 vim.wo.relativenumber = true
      		 vim.wo.number = false
      	end,
      })
    '';
  };
}
