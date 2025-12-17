-- Latest Weekly TODOs Picker
-- Searches for uncompleted todos in the most recent weekly review files

local M = {}

-- Get the most recent weekly review files
local function get_latest_weekly_files()
	local notes_dir = vim.fn.expand("~/projects/notes")

	-- Find all weekly review markdown files, sorted by modification time
	-- Looks for files matching "weekly" pattern in the notes directory
	local cmd = string.format(
		"fd -t f 'weekly.*\\.md$' %s --max-depth 2 -x ls -t {} + 2>/dev/null | head -2",
		vim.fn.shellescape(notes_dir)
	)

	local files = vim.fn.systemlist(cmd)

	-- Filter out empty lines
	local valid_files = {}
	for _, file in ipairs(files) do
		if file and file ~= "" then
			table.insert(valid_files, file)
		end
	end

	return valid_files
end

-- Search for todos and display in Snacks picker
function M.search_latest_todos()
	local files = get_latest_weekly_files()

	if #files == 0 then
		vim.notify("No weekly review files found in ~/projects/notes", vim.log.levels.WARN)
		return
	end

	local todos = {}

	for _, file in ipairs(files) do
		local ok, lines = pcall(vim.fn.readfile, file)
		if ok and lines then
			local filename = vim.fn.fnamemodify(file, ":t:r")

			for i, line in ipairs(lines) do
				-- Match uncompleted todos: [ ], [!], [-]
				-- This matches tasks that are:
				-- - [ ] uncompleted
				-- - [!] important/blocked
				-- - [-] in progress/cancelled
				if line:match("^%s*%- %[[ !%-]%]") then
					table.insert(todos, {
						filename = file,
						lnum = i,
						col = 1,
						text = line:gsub("^%s*", ""), -- Remove leading whitespace
						display = string.format("%s:%d: %s", filename, i, line:gsub("^%s*", "")),
					})
				end
			end
		end
	end

	if #todos == 0 then
		vim.notify("No pending todos found in latest weekly reviews", vim.log.levels.INFO)
		return
	end

	-- Use Snacks picker with custom items
	local Snacks = require("snacks")

	Snacks.picker.pick({
		prompt = "Latest Week TODOs",
		items = todos,
		format = function(item)
			return item.display
		end,
		confirm = function(item)
			vim.cmd(string.format("edit +%d %s", item.lnum, item.filename))
		end,
	})
end

-- Alternative: Use grep-based search for live filtering
function M.grep_latest_todos()
	local files = get_latest_weekly_files()

	if #files == 0 then
		vim.notify("No weekly review files found in ~/projects/notes", vim.log.levels.WARN)
		return
	end

	local Snacks = require("snacks")

	-- Use Snacks grep picker with the latest files
	Snacks.picker.grep({
		prompt = "Search TODOs (grep)",
		search = "^\\s*- \\[([ !-])\\]", -- Regex pattern for uncompleted todos
		grep_type = "regex",
		cwd = vim.fn.fnamemodify(files[1], ":h"),
		-- Pass the files to search
		files = files,
	})
end

-- Setup function to create user commands
function M.setup()
	-- Create user commands
	vim.api.nvim_create_user_command("LatestTodos", function()
		M.search_latest_todos()
	end, {
		desc = "Search todos in latest weekly reviews",
	})

	vim.api.nvim_create_user_command("LatestTodosGrep", function()
		M.grep_latest_todos()
	end, {
		desc = "Grep todos in latest weekly reviews",
	})
end

return M
