local M = {};

M.abc = {
  n = {
    ["<leader>bca"] = {"<cmd>%bd|e#<cr>",  "Close all buffes except current one" },
    ["<leader>uu"] = {"<cmd>Telescope undo<cr>",  "Show undoo tree" },
    ["<C-d>"] = {"<C-d>zz",  "Keep cursor in middle when jumping" },
    ["<C-u>"] = {"<C-u>zz",  "Keep cursor in middle when jumping" },
    ["J"] = {"mzJ`z",  "Keep cusors in middle" },
    ["n"] = {"nzzzv", "Fwd  search '/' or '?'" },
    ["N"] = {"Nzzzv", "Back search '/' or '?'" },
    ["<leader>o"] = {'o<Esc>0"_D', "Create a new line below without leaving normal mode" },
    ["<leader>O"] = {'O<Esc>0"_D', "Create a new line above without leaving normal mode" },
 },
  v = {
    [">"] = {">gv",  "Stay in visual mode during outdent" },
    ["<"] = {"<gv",  "Stay in visual mode during indent" },
 },
 x = {
    ["<leader>p"] = {"'_dP'",  "Paste without updating register" },
 }
}

return M
