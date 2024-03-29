{lib, ...}: {
  programs.nixvim = {
    plugins = {
      auto-session = {
        enable = true;
        extraOptions = {
          auto_save_enabled = true;
          auto_restore_enabled = true;
        };
      };

      mini = {
        enable = true;
        modules = {
          starter = {
            header = lib.concatLines [
              "███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
              "████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
              "██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
              "██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
              "██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
              "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
            ];
            items = [];
          };
        };
      };
    };
    extraConfigLua = ''
      local starter = require('mini.starter')
      local my_items = {
      	starter.sections.builtin_actions(),
      	{ name = 'Recent Files', action = ':Telescope oldfiles', section = 'Telescope' },
      	{ name = 'File Brower', action = ':Telescope file_browser', section = 'Telescope' },
      	-- starter.sections.recent_files(10, false),
      	-- starter.sections.recent_files(10, true),
      	-- Use this if you set up 'mini.sessions'
      }
      starter.setup({
      	-- Whether to open starter buffer on VimEnter. Not opened if Neovim was
      	-- started with intent to show something else.
      	autoopen = true,

      	-- Whether to evaluate action of single active item
      	evaluate_single = true,

      	-- Items to be displayed. Should be an array with the following elements:
      	-- - Item: table with <action>, <name>, and <section> keys.
      	-- - Function: should return one of these three categories.
      	-- - Array: elements of these three types (i.e. item, array, function).
      	-- If `nil` (default), default items will be used (see |mini.starter|).
      	items = my_items,

      	-- Header to be displayed before items. Should be a string or function
      	-- evaluating to single string (use `\n` for new lines).
      	-- If `nil` (default), polite greeting will be used.
      	header = nil,

      	-- Footer to be displayed after items. Should be a string or function
      	-- evaluating to string. If `nil`, default usage help will be shown.
      	footer = nil,


      	-- Array  of functions to be applied consecutively to initial content.
      	-- Each function should take and return content for 'Starter' buffer (see
      	-- |mini.starter| for more details).
      	content_hooks = {
      		starter.gen_hook.adding_bullet(),
      		starter.gen_hook.indexing('all', { 'Builtin actions', 'Telescope', 'Bookmarks'}),
      		starter.gen_hook.padding(5, 2),
      		starter.gen_hook.aligning('left', 'top'),
      	},

      	-- Characters to update query. Each character will have special buffer
      	-- mapping overriding your global ones. Be careful to not add `:` as it
      	-- allows you to go into command mode.
      	query_updaters = [[abcdefghijklmnopqrstuvwxyz0123456789_-.]],
      })
    '';
  };
}
