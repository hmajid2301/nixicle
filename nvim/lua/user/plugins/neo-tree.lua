-- return {
--   "nvim-neo-tree/neo-tree.nvim",
--   opts = {
--     filesystem = {
--       bind_to_cwd = true,
--       filtered_items = {
--         visible = true,
--         hide_dotfiles = false,
--         hide_gitignored = false,
--       },
--     }
--   },
-- }

return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
        hide_gitignored = false,
        hide_by_name = {
          "thumbs.db",
          "node_modules",
        },
      },
    },
  },
}
