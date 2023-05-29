return {
  {
    "renerocksai/telekasten.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "renerocksai/calendar-vim" },
    cmd = { "Telekasten" },
    keys = {
      { "<leader>nn", "<cmd>Telekasten panel<cr>", desc = "open panel" },
      { "<leader>nb", "<cmd>Telekasten show_backlink<cr>", desc = "backlinks" },
      { "<leader>nf", "<cmd>Telekasten find_notes<cr>", desc = "find" },
      { "<leader>ng", "<cmd>Telekasten follow_link<cr>", desc = "goto link" },
      { "<leader>nl", "<cmd>Telekasten insert_link<cr>", desc = "insert link" },
      { "<leader>nn", "<cmd>Telekasten new_templated_note<cr>", desc = "new" },
      { "<leader>ns", "<cmd>Telekasten search_notes<cr>", desc = "search" },
      { "<leader>nt", "<cmd>Telekasten goto_today<cr>", desc = "today" },
    },
    opts = {
      home = vim.fn.expand("~/notes"),
    },
  },
}
