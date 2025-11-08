vim.api.nvim_create_autocmd("FileType", {
	desc = "Remove formatoptions",
	callback = function()
		vim.opt.formatoptions:remove({ "c", "r", "o" })
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	desc = "Generate helptags for custom documentation",
	once = true,
	callback = function()
		local doc_path = vim.fn.stdpath("config") .. "/doc"
		if vim.fn.isdirectory(doc_path) == 1 then
			vim.cmd("silent! helptags " .. doc_path)
		end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function(args)
		local filetype = vim.bo[args.buf].filetype
		local excluded_filetypes = {
			"blink-cmp-menu",
			"dropbar_preview",
			"fidget",
			"gitrebase",
			"gitcommit",
			"gitconfig",
			"oil",
			"lazy",
			"mason",
			"help",
			"checkhealth",
			"TelescopePrompt",
			"TelescopeResults",
			"",
		}

		for _, ft in ipairs(excluded_filetypes) do
			if filetype == ft then
				return
			end
		end

		local success, err = pcall(function()
			local ts_lang = vim.treesitter.language.get_lang(filetype)
			if not ts_lang then
				return
			end

			local parser_ok, _ = pcall(vim.treesitter.language.add, ts_lang)
			if not parser_ok then
				return
			end

			local has_parser = pcall(vim.treesitter.get_parser, args.buf, ts_lang)
			if not has_parser then
				return
			end

			vim.treesitter.start(args.buf)
		end)
	end,
})
