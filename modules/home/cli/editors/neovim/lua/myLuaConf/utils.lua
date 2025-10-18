local M = {}

--- Show a random tip from notes.md on startup
function M.show_tip()
	local home = os.getenv("HOME")
	local notes_path = home .. "/nixicle/modules/home/cli/editors/neovim/tips.md"

	-- Check if file exists
	local file = io.open(notes_path, "r")
	if not file then
		return
	end

	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end
	file:close()

	-- Parse markdown to get sections with bullet points
	local sections = {}
	local current_section = nil

	for _, line in ipairs(lines) do
		-- Check for markdown headers (##)
		if line:match("^## (.+)") then
			current_section = line:match("^## (.+)")
			sections[current_section] = {}
		elseif line:match("^%- (.+)") and current_section then
			-- Check for bullet points
			table.insert(sections[current_section], line:match("^%- (.+)"))
		end
	end

	-- Get all tips with their context
	local tips = {}
	for section, bullets in pairs(sections) do
		for _, bullet in ipairs(bullets) do
			table.insert(tips, { section = section, tip = bullet })
		end
	end

	if #tips == 0 then
		return
	end

	-- Select a random tip
	math.randomseed(os.time())
	local random_tip = tips[math.random(#tips)]

	-- Create a new buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

	-- Set buffer content
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

	-- Calculate window size and position
	local width = math.min(100, vim.o.columns - 4)
	local height = #content + 2
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Open floating window
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	-- Set window options
	vim.api.nvim_win_set_option(win, "winblend", 0)

	-- Close on any key press
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })

	-- Close on any other key
	local close_on_key = function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.keymap.set("n", "<Space>", close_on_key, { buffer = buf, silent = true })
	for i = 33, 126 do -- Printable ASCII characters
		local char = string.char(i)
		if char ~= "q" then
			vim.keymap.set("n", char, close_on_key, { buffer = buf, silent = true })
		end
	end
end

return M
