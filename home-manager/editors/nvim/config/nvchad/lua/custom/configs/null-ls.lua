
local null_ls = require "null-ls"

local formatting = null_ls.builtins.formatting
local lint = null_ls.builtins.diagnostics

local sources = {
   code_actions.statix,
   formatting.alejandra,
   diagnostics.deadnix,
}

null_ls.setup {
   debug = true,
   sources = sources,
}

