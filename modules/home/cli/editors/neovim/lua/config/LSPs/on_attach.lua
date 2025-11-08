return function(_, bufnr)
	-- we create a function that lets us more easily define mappings specific
	-- for LSP related items. It sets the mode, buffer and description for us each time.

	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	-- vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Actions" })
	nmap("<leader>cr", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
	nmap("gds", "<cmd>split | lua vim.lsp.buf.definition()<CR>", "[G]oto [D]efinition in [S]plit")
	nmap("gdv", "<cmd>vsplit | lua vim.lsp.buf.definition()<CR>", "[G]oto [D]efinition [V]ertical")
	nmap("gdt", "<cmd>tab split | lua vim.lsp.buf.definition()<CR>", "[G]oto [D]efinition in [T]ab")
	nmap("<leader>lR", "<cmd>LspRestart<cr>", "Restart LSP")

	-- NOTE: why are these functions that call the telescope builtin?
	-- because otherwise they would load telescope eagerly when this is defined.
	-- due to us using the on_require handler to make sure it is available.
	if nixCats("general.telescope") then
		nmap("<leader>gr", function()
			require("telescope.builtin").lsp_references()
		end, "[G]oto [R]eferences")
		nmap("<leader>gi", function()
			require("telescope.builtin").lsp_implementations()
		end, "[G]oto [I]mplementation")
		nmap("<leader>ds", function()
			require("telescope.builtin").lsp_document_symbols()
		end, "[D]ocument [S]ymbols")
		nmap("<leader>ws", function()
			require("telescope.builtin").lsp_dynamic_workspace_symbols()
		end, "[W]orkspace [S]ymbols")
	end -- TODO: someone who knows the builtin versions of these to do instead help me out please.

	nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")

	-- See `:help K` for why this keymap
	nmap("K", function()
		vim.lsp.buf.hover({ border = "rounded" })
	end, "Hover Documentation")

	vim.keymap.set("i", "<C-k>", function()
		vim.lsp.buf.signature_help({ border = "rounded" })
	end, { desc = "Signature Documentation" })

	-- Lesser used LSP functionality
	nmap("<leader>gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })
end
