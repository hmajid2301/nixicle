-- NOTE: various, non-plugin config
require("myLuaConf.opts_and_keys")

-- NOTE: register an extra lze handler with the spec_field 'for_cat'
-- that makes enabling an lze spec for a category slightly nicer
require("lze").register_handlers(require("nixCatsUtils.lzUtils").for_cat)

-- NOTE: Register another one from lzextras. This one makes it so that
-- you can set up lsps within lze specs,
-- and trigger lspconfig setup hooks only on the correct filetypes
require("lze").register_handlers(require("lzextras").lsp)

-- NOTE: general plugins
require("myLuaConf.plugins")
require("myLuaConf.plugins.colorscheme")

-- NOTE: obviously, more plugins, but more organized by what they do below

-- I dont need to explain why this is called lsp right?
require("myLuaConf.LSPs")

-- NOTE: we even ask nixCats if we included our debug stuff in this setup! (we didnt)
-- But we have a good base setup here as an example anyway!
if nixCats("debug") then
	require("myLuaConf.debug")
end
if nixCats("test") then
	require("myLuaConf.test")
end
-- NOTE: we included these though! Or, at least, the category is enabled.
-- these contain nvim-lint and conform setups.
if nixCats("lint") then
	require("myLuaConf.lint")
end
if nixCats("format") then
	require("myLuaConf.format")
end
-- NOTE: I didnt actually include any linters or formatters in this configuration,
-- but it is enough to serve as an example.

-- NOTE: Show random tip on startup
local function show_tip()
	local home = os.getenv("HOME")
	local notes_path = home .. "/nixicle/modules/home/cli/editors/neovim/tips.md"

	local file = io.open(notes_path, "r")
	if not file then
		return
	end

	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	local sections = {}
	local current_section = nil

	for _, line in ipairs(lines) do
		if line:match("^## (.+)") then
			current_section = line:match("^## (.+)")
			sections[current_section] = {}
		elseif line:match("^%- (.+)") and current_section then
			table.insert(sections[current_section], line:match("^%- (.+)"))
		end
	end

	local tips = {}
	for section, bullets in pairs(sections) do
		for _, bullet in ipairs(bullets) do
			table.insert(tips, { section = section, tip = bullet })
		end
	end

	if #tips == 0 then
		return
	end

	math.randomseed(os.time())
	local random_tip = tips[math.random(#tips)]

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

	local content = {
		"",
		"## " .. random_tip.section,
		"",
		"- " .. random_tip.tip,
		"",
		"",
		"Press any key to continue...",
	}

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	local width = math.min(100, vim.o.columns - 4)
	local height = #content + 2
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	vim.api.nvim_win_set_option(win, "winblend", 0)

	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })

	local close_on_key = function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "<Space>", close_on_key, { buffer = buf, silent = true })
	for i = 33, 126 do
		local char = string.char(i)
		if char ~= "q" then
			vim.keymap.set("n", char, close_on_key, { buffer = buf, silent = true })
		end
	end
end

vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("ShowTips", { clear = true }),
	callback = function()
		if vim.fn.argc() == 0 then
			show_tip()
		end
	end,
	desc = "Show random tip from tips.md on startup",
})
