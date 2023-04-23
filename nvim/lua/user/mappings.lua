-- Mapping data with "desc" stored directly by vim.keymap.set().
--
-- Please use this mappings table to set keyboard mapping since this is the
-- lower level configuration and more robust one. (which-key will
-- automatically pick-up stored data by this setting.)
return {
  -- first key is the mode
  n = {
    -- second key is the lefthand side of the map
    -- mappings seen under group name "Buffer"
    ["<leader>bn"] = { "<cmd>tabnew<cr>", desc = "New tab" },
    ["<leader>bD"] = {
      function()
        require("astronvim.utils.status").heirline.buffer_picker(function(bufnr)
          require("astronvim.utils.buffer").close(
            bufnr)
        end)
      end,
      desc = "Pick to close",
    },
    ["J"] = { "mzJ`z", desc = "combine with line up" },
    ["<C-d>"] = { "<C-d>zz", desc = "Keep cursor in middle when jumping" },
    ["<C-u>"] = { "<C-u>zz", desc = "Keep cursor in middle when jumping" },
    ["<leader>cd"] = { require("telescope").extensions.zoxide.list, desc = "Change directory using zoxide" },
    ["<C-o>"] = { "o<Esc>", desc = "Create new line below without leaving normal mode" },
    ["<C-O>"] = { "O<Esc>", desc = "Create new line above without leaving normal mode" },
    ["<leader>u"] = { "<cmd>Telescope undo<cr>", desc = "Show undoo tree" },
  },
  x = {
    ["<leader>p"] = { "\"_dP", desc = "Paste without updating register" },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
  v = {
    ["<"] = { "<gv", desc = "Stay in visual mode during outdent" },
    [">"] = { ">gv", desc = "Stay in visual mode during indent" },
    ["J"] = { ":m >+1<CR>gv=gv", desc = "Mouse selected lines down" },
    ["K"] = { ":m >-2<CR>gv=gv", desc = "Mouse selected lines up" },
  }
}
