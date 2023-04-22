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
    -- tables with the `name` key will be registered with which-key if it's installed
    -- this is useful for naming menus
    ["<leader>b"] = { name = "Buffers" },
    -- quick save
    -- ["<C-s>"] = { ":w!<cr>", desc = "Save File" },  -- change description but the same command
    ["<leader>cd"] = { require("telescope").extensions.zoxide.list, desc = "Change directory using zoxide" },
    ["<C-o>"] = { "o<Esc>", desc = "Create new line below without leaving normal mode" },
    ["<C-O>"] = { "O<Esc>", desc = "Create new line above without leaving normal mode" },
    ["<leader>u"] = { "<cmd>Telescope undo<cr>", desc = "Show undoo tree" },
    --
    -- Trouble
    ["<leader>xx"] = { "<cmd>TroubleToggle<CR>", desc = "Trouble: Toggle" },
    ["<leader>xw"] = { "<cmd>Trouble workspace_diagnostics<CR>", desc = "Trouble: Workspace Diagnostics" },
    ["<leader>xf"] = { "<cmd>Trouble document_diagnostics<CR>", desc = "Trouble: Document Diagnostics" },
    ["<leader>xq"] = { "<cmd>Trouble quickfix<CR>", desc = "Trouble: Quick Fix" },
    ["<leader>xr"] = { "<cmd>Trouble lsp_references<CR>", desc = "Trouble: Open LSP References" },
    ["<leader>xd"] = { "<cmd>Trouble lsp_definitions<CR>", desc = "Trouble: Open Defitions" },
  },
  t = {
    -- setting a mapping to false will disable it
    -- ["<esc>"] = false,
  },
  v = {
    ["<"] = { "<gv", desc = "Stay in visual mode during outdent" },
    [">"] = { ">gv", desc = "Stay in visual mode during indent" },
  }
}
