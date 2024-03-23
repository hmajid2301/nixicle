function reload_config()
	RELOAD = require("plenary.reload").reload_module
	RELOAD(os.getenv("MYVIMRC"))
	vim.cmd [[luafile $MYVIMRC]]
	print(vim.inspect(name .. " RELOADED!!!"))
end

function toggle_relative_numbers()
	if vim.wo.relativenumber then
		vim.wo.relativenumber = false
		vim.wo.number = true
	else
		vim.wo.relativenumber = true
		vim.wo.number = false
	end
end

function toggle_inlay_hints()
	if vim.g.inlay_hints_visible then
		vim.g.inlay_hints_visible = false
		vim.lsp.inlay_hint.enable(vim.api.nvim_get_current_buf() or 0, false)
	else
		vim.g.inlay_hints_visible = true
		vim.lsp.inlay_hint.enable(vim.api.nvim_get_current_buf() or 0, true)
	end
end

vim.api.nvim_set_keymap('n', '<leader>vl', '<Cmd>lua toggle_relative_numbers()<CR>',
	{ noremap = true, silent = true, desc = "Toggle relative lines" })
vim.api.nvim_set_keymap('n', '<leader>vh', '<Cmd>lua toggle_inlay_hints()<CR>',
	{ noremap = true, silent = true, desc = "Toggle inlay hints" })
vim.api.nvim_set_keymap('n', '<Leader>vs', '<Cmd>lua reload_config()<CR>',
	{ silent = true, noremap = true, desc = "Reload config" })
