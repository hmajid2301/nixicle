local M = {}

M.config = {
	socket_path = nil,
	context_format = "reference",
	set_default_keymaps = true,
	send_behavior = "followUp",
	auto_read = true,
	live_context = {
		enabled = true,
		debounce_ms = 150,
		include_buffer_text = false,
		max_buffer_bytes = 200000,
		max_selection_bytes = 50000,
	},
}

M._queue = {}
M._sync_timer = nil
M._reload_timer = nil

local SOCKETS_DIR = "/tmp/pi-nvim-sockets"
local LATEST_LINK = "/tmp/pi-nvim-latest.sock"

local function truncate_text(text, max_bytes)
	if not text or text == "" then
		return text, false
	end
	if not max_bytes or max_bytes <= 0 then
		return text, false
	end
	if #text <= max_bytes then
		return text, false
	end
	return text:sub(1, max_bytes), true
end

local function get_display_name(state)
	local target = state.file or state.absFile
	if target and target ~= "" then
		return vim.fn.fnamemodify(target, ":t")
	end
	if state.buftype and state.buftype ~= "" then
		return string.format("[%s]", state.buftype)
	end
	return "[no file]"
end

local function format_status(state)
	if not state then
		return "nvim: --"
	end
	local parts = { string.format("nvim: %s", get_display_name(state)) }
	if state.selection then
		table.insert(parts, string.format("sel %d-%d", state.selection.startLine, state.selection.endLine))
	elseif state.cursor then
		table.insert(parts, string.format("L%d", state.cursor.line))
	end
	return table.concat(parts, " ")
end

local function ensure_autoread()
	if not vim.o.autoread then
		vim.o.autoread = true
	end
end

local function get_visual_selection_state(max_bytes)
	local mode = vim.fn.mode()
	if not mode:match("^[vV\022]") then
		return nil
	end

	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	if not start_pos or not end_pos then
		return nil
	end

	local start_line, start_col = start_pos[2], start_pos[3]
	local end_line, end_col = end_pos[2], end_pos[3]
	if start_line > end_line or (start_line == end_line and start_col > end_col) then
		start_line, end_line = end_line, start_line
		start_col, end_col = end_col, start_col
	end

	local ok, lines = pcall(vim.fn.getregion, start_pos, end_pos, { type = vim.fn.visualmode() })
	if not ok or not lines or vim.tbl_isempty(lines) then
		return nil
	end

	local text, truncated = truncate_text(table.concat(lines, "\n"), max_bytes)
	return {
		startLine = start_line,
		endLine = end_line,
		text = text,
		truncated = truncated,
	}
end

function M.get_editor_state()
	local buf = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(buf) then
		return nil
	end

	local cfg = M.config.live_context or {}
	local abs_file = vim.api.nvim_buf_get_name(buf)
	local rel_file = abs_file ~= "" and vim.fn.fnamemodify(abs_file, ":.") or ""
	local cursor = vim.api.nvim_win_get_cursor(0)
	local buftype = vim.bo[buf].buftype
	local filetype = vim.bo[buf].filetype
	local modified = vim.bo[buf].modified
	local selection = get_visual_selection_state(cfg.max_selection_bytes)

	local state = {
		cwd = vim.uv.cwd(),
		file = rel_file,
		absFile = abs_file,
		filetype = filetype,
		modified = modified,
		buftype = buftype,
		cursor = { line = cursor[1], col = cursor[2] + 1 },
		selection = selection,
	}

	if buftype == "" and cfg.include_buffer_text then
		local should_include_buffer = modified or abs_file == ""
		if should_include_buffer then
			local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
			local text, truncated = truncate_text(table.concat(lines, "\n"), cfg.max_buffer_bytes)
			state.bufferText = text
			state.bufferTruncated = truncated
		end
	end

	return state
end

function M.send_editor_state(cb)
	local state = M.get_editor_state()
	if not state then
		if cb then
			cb("No active buffer")
		end
		return
	end
	M.send_raw({ type = "editor_state", state = state }, cb, { silent = true })
end

function M.schedule_editor_state_sync(delay_ms)
	if not (M.config.live_context and M.config.live_context.enabled) then
		return
	end
	if M._sync_timer then
		M._sync_timer:stop()
		M._sync_timer:close()
	end
	M._sync_timer = vim.uv.new_timer()
	if not M._sync_timer then
		return
	end
	M._sync_timer:start(delay_ms or (M.config.live_context.debounce_ms or 150), 0, vim.schedule_wrap(function()
		if M._sync_timer then
			M._sync_timer:stop()
			M._sync_timer:close()
			M._sync_timer = nil
		end
		M.send_editor_state()
	end))
end

function M.setup_live_context_sync()
	local group = vim.api.nvim_create_augroup("PiNvimLiveContext", { clear = true })
	vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "BufWinEnter", "BufWritePost", "InsertLeave", "TextChanged", "TextChangedI", "ModeChanged", "CursorMoved" }, {
		group = group,
		callback = function()
			M.schedule_editor_state_sync()
		end,
	})
end

function M.format_context(ctx)
	if M.config.context_format == "reference" then
		if ctx.type == "selection" and ctx.start_line then
			return string.format("@%s:%d-%d", ctx.file, ctx.start_line, ctx.end_line)
		end
		local path = ctx.file ~= "" and ctx.file or ctx.abs_file
		return string.format("@%s", path)
	end

	if ctx.type == "selection" then
		local header = string.format("%s lines %d-%d", ctx.file, ctx.start_line, ctx.end_line)
		return string.format("From %s:\n```%s\n%s\n```", header, ctx.ft or "", ctx.text or "")
	elseif ctx.type == "buffer" then
		return string.format("File: %s\n```%s\n%s\n```", ctx.file, ctx.ft or "", ctx.text or "")
	end

	return ctx.abs_file
end

local function get_current_file_context()
	local abs_file = vim.fn.expand("%:p")
	local rel_file = vim.fn.expand("%:.")
	if abs_file == "" then
		return nil
	end
	return {
		type = "file",
		file = rel_file,
		abs_file = abs_file,
	}
end

local function get_selection_context()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local lines = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.visualmode() })
	local selection_text = table.concat(lines, "\n")
	if selection_text == "" then
		return nil
	end
	local file = vim.fn.expand("%:.")
	local abs_file = vim.fn.expand("%:p")
	return {
		type = "selection",
		file = file,
		abs_file = abs_file,
		start_line = start_pos[2],
		end_line = end_pos[2],
		ft = vim.bo.filetype,
		text = selection_text,
	}
end

function M.build_message(prompt, ctx)
	if not prompt or prompt == "" then
		return ctx
	end
	if not ctx or ctx == "" then
		return prompt
	end
	return string.format("%s\n\n%s", prompt, ctx)
end

function M.find_socket_for_cwd()
	if M.config.socket_path then
		return M.config.socket_path
	end

	local cwd = vim.uv.cwd()
	local ok, files = pcall(vim.fn.glob, SOCKETS_DIR .. "/*.info", false, true)
	if ok and files then
		local best_sock = nil
		local best_mtime = 0
		for _, info_path in ipairs(files) do
			local content_ok, content = pcall(vim.fn.readfile, info_path)
			if content_ok and content and content[1] then
				local parsed_ok, info = pcall(vim.json.decode, content[1])
				if parsed_ok and info then
					local sock = info_path:sub(1, -6)
					local stat = vim.uv.fs_stat(sock)
					if stat and stat.type == "socket" and info.cwd == cwd then
						if stat.mtime.sec > best_mtime then
							best_mtime = stat.mtime.sec
							best_sock = sock
						end
					end
				end
			end
		end
		if best_sock then
			return best_sock
		end

		for _, info_path in ipairs(files) do
			local sock = info_path:sub(1, -6)
			local stat = vim.uv.fs_stat(sock)
			if stat and stat.type == "socket" and stat.mtime.sec > best_mtime then
				best_mtime = stat.mtime.sec
				best_sock = sock
			end
		end
		if best_sock then
			return best_sock
		end
	end

	if vim.uv.fs_stat(LATEST_LINK) then
		return LATEST_LINK
	end
	return nil
end

function M.send_raw(msg, cb, opts)
	opts = opts or {}
	local sock_path = M.find_socket_for_cwd()
	if not sock_path then
		local err = "No pi session found. Is pi running with the pi-nvim extension?"
		if not opts.silent then
			vim.notify(err, vim.log.levels.ERROR)
		end
		if cb then
			cb(err, nil)
		end
		return
	end

	local client = vim.uv.new_pipe(false)
	if not client then
		local err = "Failed to create pipe"
		if not opts.silent then
			vim.notify(err, vim.log.levels.ERROR)
		end
		if cb then
			cb(err, nil)
		end
		return
	end

	client:connect(sock_path, function(err)
		if err then
			vim.schedule(function()
				if not opts.silent then
					vim.notify("Failed to connect to pi: " .. err, vim.log.levels.ERROR)
				end
				if cb then
					cb(err, nil)
				end
			end)
			return
		end

		local payload = vim.json.encode(msg) .. "\n"
		client:write(payload)

		local buf = ""
		client:read_start(function(read_err, data)
			if read_err then
				client:close()
				vim.schedule(function()
					if cb then
						cb(read_err, nil)
					end
				end)
				return
			end

			if data then
				buf = buf .. data
				local nl = buf:find("\n")
				if nl then
					local line = buf:sub(1, nl - 1)
					client:read_stop()
					client:close()
					vim.schedule(function()
						local ok, resp = pcall(vim.json.decode, line)
						if ok and resp then
							if cb then
								cb(nil, resp)
							end
						else
							if cb then
								cb("Invalid response from pi", nil)
							end
						end
					end)
				end
			else
				client:close()
			end
		end)
	end)
end

function M.prompt(message)
	local deliver_as = M.config.send_behavior or "followUp"
	M.send_raw({ type = "prompt", message = message, deliverAs = deliver_as }, function(err, resp)
		if err then
			return
		end
		if resp and resp.ok then
			vim.notify("Sent to pi", vim.log.levels.INFO)
		else
			vim.notify("pi error: " .. (resp and resp.error or "unknown"), vim.log.levels.ERROR)
		end
	end)
end

function M.send_file()
	local file_ctx = get_current_file_context()
	if not file_ctx then
		vim.notify("No file open", vim.log.levels.WARN)
		return
	end
	local ctx_str = M.format_context({ type = "file", file = file_ctx.file, abs_file = file_ctx.abs_file })
	vim.ui.input({ prompt = "Pi prompt (file: " .. file_ctx.file .. "): " }, function(input)
		if input == nil then
			return
		end
		local message
		if input == "" then
			if M.config.context_format == "reference" then
				message = ctx_str
			else
				message = string.format("Look at this file: %s", file_ctx.abs_file)
			end
		else
			message = M.build_message(input, ctx_str)
		end
		M.prompt(message)
	end)
end

function M.send_selection()
	local selection = get_selection_context()
	if not selection then
		vim.notify("Empty selection", vim.log.levels.WARN)
		return
	end
	local ctx_str = M.format_context({
		type = "selection",
		file = selection.file,
		abs_file = selection.abs_file,
		start_line = selection.start_line,
		end_line = selection.end_line,
		ft = selection.ft,
		text = selection.text,
	})
	vim.ui.input({ prompt = "Pi prompt (selection): " }, function(input)
		if input == nil then
			return
		end
		local message
		if input == "" then
			if M.config.context_format == "reference" then
				message = ctx_str
			else
				message = string.format(
					"Look at this code from %s lines %d-%d:\n\n```%s\n%s\n```",
					selection.file,
					selection.start_line,
					selection.end_line,
					selection.ft or "",
					selection.text
				)
			end
		else
			message = M.build_message(input, ctx_str)
		end
		M.prompt(message)
	end)
end

function M.send_buffer()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local content = table.concat(lines, "\n")
	local rel_file = vim.fn.expand("%:.")
	local abs_file = vim.fn.expand("%:p")
	local ft = vim.bo.filetype
	local ctx_str = M.format_context({
		type = "buffer",
		file = rel_file,
		abs_file = abs_file,
		ft = ft,
		text = content,
	})
	vim.ui.input({ prompt = "Pi prompt (buffer): " }, function(input)
		if input == nil then
			return
		end
		local message
		if input == "" then
			if M.config.context_format == "reference" then
				message = ctx_str
			else
				message = string.format("Look at this file %s:\n\n```%s\n%s\n```", rel_file, ft, content)
			end
		else
			message = M.build_message(input, ctx_str)
		end
		M.prompt(message)
	end)
end

function M.ping()
	M.send_raw({ type = "ping" }, function(err, resp)
		if err then
			vim.notify("Pi not reachable: " .. err, vim.log.levels.ERROR)
		elseif resp and resp.type == "pong" then
			vim.notify("Pi is alive! ✓", vim.log.levels.INFO)
		else
			vim.notify("Unexpected response from pi", vim.log.levels.WARN)
		end
	end)
end

function M.list_sessions()
	if not vim.uv.fs_stat(SOCKETS_DIR) then
		vim.notify("No pi sessions found", vim.log.levels.INFO)
		return
	end

	local files = vim.fn.glob(SOCKETS_DIR .. "/*.info", false, true)
	if not files or #files == 0 then
		vim.notify("No pi sessions found", vim.log.levels.INFO)
		return
	end

	local sessions = {}
	for _, info_path in ipairs(files) do
		local content_ok, content = pcall(vim.fn.readfile, info_path)
		if content_ok and content and content[1] then
			local parsed_ok, info = pcall(vim.json.decode, content[1])
			if parsed_ok and info then
				local sock = info_path:sub(1, -6)
				local alive = vim.uv.fs_stat(sock) ~= nil
				if alive then
					local started = ""
					if info.startedAt then
						local ok2, ts = pcall(function()
							local h, mi = info.startedAt:match("T(%d+):(%d+):")
							if h and mi then
								return string.format("%s:%s", h, mi)
							end
							return info.startedAt
						end)
						if ok2 then
							started = ts
						end
					end
					table.insert(sessions, {
						cwd = info.cwd or "?",
						pid = info.pid or "?",
						started = started,
						socket = sock,
					})
				end
			end
		end
	end

	if #sessions == 0 then
		vim.notify("No pi sessions found", vim.log.levels.INFO)
		return
	end

	local items = {}
	local current = M.find_socket_for_cwd()
	for _, s in ipairs(sessions) do
		local marker = (current == s.socket) and "●" or "○"
		local time_str = s.started ~= "" and string.format(" started %s", s.started) or ""
		table.insert(items, string.format("%s %s [pid %s%s]", marker, s.cwd, s.pid, time_str))
	end

	vim.ui.select(items, { prompt = "Pi sessions:" }, function(choice, idx)
		if not choice or not idx then
			return
		end
		local session = sessions[idx]
		if session then
			M.config.socket_path = session.socket
			vim.notify(string.format("Connected to pi at %s [pid %s]", session.cwd, session.pid), vim.log.levels.INFO)
		end
	end)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	ensure_autoread()

	if M._reload_timer then
		M._reload_timer:stop()
		M._reload_timer:close()
	end
	M._reload_timer = vim.uv.new_timer()
	if M._reload_timer then
		M._reload_timer:start(0, 1000, vim.schedule_wrap(function()
			if M.find_socket_for_cwd() then
				pcall(vim.cmd, "silent! checktime")
			end
		end))
	end

	vim.api.nvim_create_user_command("PiSend", function()
		vim.ui.input({ prompt = "Pi prompt: " }, function(input)
			if input and input ~= "" then
				M.prompt(input)
			end
		end)
	end, { desc = "Send a prompt to pi" })
	vim.api.nvim_create_user_command("PiSendFile", function()
		M.send_file()
	end, { desc = "Send current file to pi with a prompt" })
	vim.api.nvim_create_user_command("PiSendSelection", function()
		M.send_selection()
	end, { range = true, desc = "Send visual selection to pi with a prompt" })
	vim.api.nvim_create_user_command("PiSendBuffer", function()
		M.send_buffer()
	end, { desc = "Send entire buffer to pi with a prompt" })
	vim.api.nvim_create_user_command("Pi", function(args)
		local selection = nil
		if args.range == 2 then
			selection = get_selection_context()
		end
		vim.ui.input({ prompt = "Pi prompt: " }, function(input)
			if input == nil then
				return
			end
			local context
			if selection then
				context = M.format_context({
					type = "selection",
					file = selection.file,
					abs_file = selection.abs_file,
					start_line = selection.start_line,
					end_line = selection.end_line,
					ft = selection.ft,
					text = selection.text,
				})
			else
				local file_ctx = get_current_file_context()
				if not file_ctx then
					vim.notify("No file open", vim.log.levels.WARN)
					return
				end
				context = M.format_context({ type = "file", file = file_ctx.file, abs_file = file_ctx.abs_file })
			end
			M.prompt(M.build_message(input, context))
		end)
	end, { range = true, desc = "Send context to pi" })
	vim.api.nvim_create_user_command("PiPing", function()
		M.ping()
	end, { desc = "Ping the pi session" })
	vim.api.nvim_create_user_command("PiSessions", function()
		M.list_sessions()
	end, { desc = "List running pi sessions" })

	if M.config.set_default_keymaps then
		vim.keymap.set("n", "<leader>Pa", ":Pi<CR>", { silent = true, desc = "Pi: send context" })
		vim.keymap.set("v", "<leader>Pa", ":Pi<CR>", { silent = true, desc = "Pi: send selection" })
		vim.keymap.set("n", "<leader>Pp", ":PiSend<CR>", { silent = true, desc = "Pi: prompt" })
		vim.keymap.set("n", "<leader>Pf", ":PiSendFile<CR>", { silent = true, desc = "Pi: file" })
		vim.keymap.set("v", "<leader>Ps", ":PiSendSelection<CR>", { silent = true, desc = "Pi: selection" })
		vim.keymap.set("n", "<leader>Pb", ":PiSendBuffer<CR>", { silent = true, desc = "Pi: buffer" })
		vim.keymap.set("n", "<leader>Pi", ":PiPing<CR>", { silent = true, desc = "Pi: ping" })
	end

	if M.config.live_context and M.config.live_context.enabled then
		M.setup_live_context_sync()
		vim.schedule(function()
			M.schedule_editor_state_sync(0)
		end)
	end
end

return M
