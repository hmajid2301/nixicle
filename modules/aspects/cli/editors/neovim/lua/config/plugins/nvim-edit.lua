local uv = vim.uv or vim.loop
local M = {}

local client = nil
local connected = false
local read_buffer = ""

local function notify(msg, level)
	vim.schedule(function()
		vim.notify(msg, level or vim.log.levels.INFO)
	end)
end

local function split_lines(text)
	local lines = vim.split(text or "", "\n", { plain = true })
	if #lines > 0 and lines[#lines] == "" then
		table.remove(lines, #lines)
	end
	return lines
end

local function apply_request_to_lines(lines, request)
	local out = vim.deepcopy(lines)
	local line = math.max(1, math.min(tonumber(request.line) or 1, #out + 1))
	local replacement = split_lines(request.content or "")

	if request.changeType == "replace" then
		table.remove(out, line)
		for i, value in ipairs(replacement) do
			table.insert(out, line + i - 1, value)
		end
	elseif request.changeType == "insert" then
		for i, value in ipairs(replacement) do
			table.insert(out, line + i - 1, value)
		end
	elseif request.changeType == "delete" then
		if line <= #out then
			table.remove(out, line)
		end
	end

	return out
end

local function discover_socket()
	local cwd = uv.cwd()
	local files = vim.fn.glob("/tmp/pi-nvim-edit-*/session.json", false, true)
	local fallback = nil
	local fallback_mtime = 0

	for _, session_file in ipairs(files) do
		local ok, raw = pcall(vim.fn.readfile, session_file)
		if ok and raw and raw[1] then
			local decoded_ok, info = pcall(vim.json.decode, raw[1])
			if decoded_ok and info and info.socket and uv.fs_stat(info.socket) then
				local stat = uv.fs_stat(info.socket)
				if info.cwd == cwd then
					return info.socket
				end
				if stat and stat.mtime.sec > fallback_mtime then
					fallback = info.socket
					fallback_mtime = stat.mtime.sec
				end
			end
		end
	end

	return fallback
end

local function send_response(response)
	if not client or not connected then
		notify("nvim-edit: not connected to Pi", vim.log.levels.ERROR)
		return
	end
	client:write(vim.json.encode(response) .. "\n")
end

local function close_review_tab()
	pcall(vim.cmd, "diffoff!")
	pcall(vim.cmd, "tabclose")
end

local function set_review_keymaps(bufnr, request, proposed_lines, temp_file)
	local opts = { buffer = bufnr, silent = true }
	vim.keymap.set("n", "<leader>pa", function()
		vim.fn.writefile(proposed_lines, request.file)
		send_response({
			type = "response",
			id = request.id,
			approved = true,
			comment = "Approved and applied in Neovim",
			editedContent = table.concat(proposed_lines, "\n"),
		})
		pcall(vim.fn.delete, temp_file)
		close_review_tab()
		notify("nvim-edit: approved and applied")
	end, vim.tbl_extend("force", opts, { desc = "Approve nvim-edit change" }))

	vim.keymap.set("n", "<leader>pr", function()
		vim.ui.input({ prompt = "Reject reason: " }, function(reason)
			send_response({ type = "response", id = request.id, approved = false, comment = reason or "Rejected" })
			pcall(vim.fn.delete, temp_file)
			close_review_tab()
			notify("nvim-edit: rejected")
		end)
	end, vim.tbl_extend("force", opts, { desc = "Reject nvim-edit change" }))

	vim.keymap.set("n", "<leader>pm", function()
		close_review_tab()
		vim.cmd("edit " .. vim.fn.fnameescape(request.file))
		vim.api.nvim_win_set_cursor(0, { math.max(1, tonumber(request.line) or 1), 0 })
		notify("Edit manually, save, then press <leader>pa to send approval to Pi")
		vim.keymap.set("n", "<leader>pa", function()
			vim.cmd("write")
			local edited = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			send_response({
				type = "response",
				id = request.id,
				approved = true,
				comment = "Manually edited in Neovim",
				editedContent = table.concat(edited, "\n"),
			})
			notify("nvim-edit: manual edit sent to Pi")
		end, { buffer = true, silent = true, desc = "Approve manual nvim-edit" })
	end, vim.tbl_extend("force", opts, { desc = "Manual nvim-edit" }))
end

function M.handle_edit_request(request)
	if not request.id or not request.file then
		return
	end
	if vim.fn.filereadable(request.file) ~= 1 then
		send_response({ type = "response", id = request.id, approved = false, comment = "File not readable in Neovim" })
		return
	end

	local original = vim.fn.readfile(request.file)
	local proposed = apply_request_to_lines(original, request)
	local temp_file = vim.fn.tempname()
	vim.fn.writefile(proposed, temp_file)

	vim.schedule(function()
		vim.cmd("tabnew " .. vim.fn.fnameescape(request.file))
		local original_buf = vim.api.nvim_get_current_buf()
		vim.cmd("vert diffsplit " .. vim.fn.fnameescape(temp_file))
		local proposed_buf = vim.api.nvim_get_current_buf()
		vim.cmd("windo diffthis")
		set_review_keymaps(original_buf, request, proposed, temp_file)
		set_review_keymaps(proposed_buf, request, proposed, temp_file)
		vim.notify(string.format(
			"nvim-edit: %s %s:%d\n%s\n<leader>pa approve, <leader>pr reject, <leader>pm manual",
			request.changeType,
			vim.fn.fnamemodify(request.file, ":~:."),
			tonumber(request.line) or 1,
			request.comment or ""
		), vim.log.levels.INFO)
	end)
end

function M.handle_message(line)
	local ok, msg = pcall(vim.json.decode, line)
	if not ok or not msg then
		return
	end
	if msg.type == "edit" then
		M.handle_edit_request(msg)
	elseif msg.type == "pong" then
		notify("nvim-edit: Pi reachable")
	end
end

function M.connect(opts)
	opts = opts or {}
	if client and connected then
		return true
	end

	local socket_path = opts.socket_path or discover_socket()
	if not socket_path then
		if not opts.silent then
			notify("nvim-edit: no Pi nvim-edit socket found", vim.log.levels.WARN)
		end
		return false
	end

	client = uv.new_pipe(false)
	if not client then
		notify("nvim-edit: failed to create pipe", vim.log.levels.ERROR)
		return false
	end

	client:connect(socket_path, function(err)
		if err then
			connected = false
			client = nil
			if not opts.silent then
				notify("nvim-edit: failed to connect to Pi: " .. err, vim.log.levels.ERROR)
			end
			return
		end

		connected = true
		notify("nvim-edit: connected to Pi")
		client:read_start(function(read_err, chunk)
			if read_err then
				connected = false
				notify("nvim-edit: read error: " .. read_err, vim.log.levels.ERROR)
				return
			end
			if not chunk then
				connected = false
				return
			end
			read_buffer = read_buffer .. chunk
			local newline = read_buffer:find("\n", 1, true)
			while newline do
				local line = vim.trim(read_buffer:sub(1, newline - 1))
				read_buffer = read_buffer:sub(newline + 1)
				if line ~= "" then
					M.handle_message(line)
				end
				newline = read_buffer:find("\n", 1, true)
			end
		end)
	end)

	return true
end

function M.ping()
	if not client or not connected then
		if not M.connect({ silent = false }) then
			return
		end
	end
	client:write(vim.json.encode({ type = "ping" }) .. "\n")
end

function M.close()
	if client then
		client:close()
	end
	client = nil
	connected = false
end

function M.setup()
	vim.api.nvim_create_user_command("NvimEditConnect", function()
		M.connect({ silent = false })
	end, { desc = "Connect to Pi nvim-edit socket" })
	vim.api.nvim_create_user_command("NvimEditPing", function()
		M.ping()
	end, { desc = "Ping Pi nvim-edit socket" })
	M.connect({ silent = true })
end

return M
