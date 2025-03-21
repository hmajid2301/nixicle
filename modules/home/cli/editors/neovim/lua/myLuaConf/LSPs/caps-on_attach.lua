local M = {}

local function custom_hover(_, result, ctx, _)
	if not (result and result.contents) then
		return
	end

	-- Modern markdown conversion
	local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)

	-- Replace trim_empty_lines with vim.split/vim.trim
	local buf_lines = vim.split(table.concat(markdown_lines, "\n"), "\n", { plain = true })
	buf_lines = vim.tbl_map(function(line)
		return vim.trim(line)
	end, buf_lines)

	-- Add padding through buffer lines manipulation
	local pad_top = { "", "" }
	local pad_bottom = { "", "" }
	local pad_sides = "  " -- 2-space padding

	buf_lines = vim.list_extend(pad_top, buf_lines)
	buf_lines = vim.list_extend(buf_lines, pad_bottom)

	buf_lines = vim.tbl_map(function(line)
		return pad_sides .. line .. pad_sides
	end, buf_lines)

	-- Modern window creation with border
	local bufnr, winnr = vim.lsp.util.open_floating_preview(buf_lines, "markdown", {
		border = {
			{ "╭", "FloatBorder" },
			{ "─", "FloatBorder" },
			{ "╮", "FloatBorder" },
			{ "│", "FloatBorder" },
			{ "╯", "FloatBorder" },
			{ "─", "FloatBorder" },
			{ "╰", "FloatBorder" },
			{ "│", "FloatBorder" },
		},
		focusable = false,
		max_width = 80,
		focus_id = ctx.method,
		-- Direct window options instead of nvim_win_set_option
		winhl = "Normal:NormalFloat,FloatBorder:FloatBorder",
	})

	return bufnr, winnr
end

-- Set handler with modern API
vim.lsp.handlers["textDocument/hover"] = custom_hover

function M.on_attach(_, bufnr)
	-- we create a function that lets us more easily define mappings specific
	-- for LSP related items. It sets the mode, buffer and description for us each time.

	local nmap = function(keys, func, desc)
		if desc then
			desc = "LSP: " .. desc
		end

		vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
	end

	nmap("<leader>cr", vim.lsp.buf.rename, "[R]e[n]ame")
	nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
	nmap("<leader>gd", vim.lsp.buf.definition, "[G]oto [D]efinition")

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
	nmap("K", vim.lsp.buf.hover, "Hover Documentation")
	vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, { desc = "Signature Documentation" })

	-- Lesser used LSP functionality
	nmap("<leader>gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
		vim.lsp.buf.format()
	end, { desc = "Format current buffer with LSP" })
end

function M.get_capabilities(server_name)
	-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
	-- if you make a package without it, make sure to check if it exists with nixCats!
	-- local capabilities = vim.lsp.protocol.make_client_capabilities()
	-- if nixCats("general.cmp") then
	-- 	capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
	-- end
	-- capabilities.textDocument.completion.completionItem.snippetSupport = true
	local capabilities = require("cmp_nvim_lsp").default_capabilities()
	return capabilities
end
return M
