local M = {}

--- Get the branch name with git-dir and worktree support
--- @param worktree table<string, string>|nil # a table specifying the `toplevel` and `gitdir` of a worktree
--- @param as_path string|nil # execute the git command from specific path
--- @return string branch # The branch name
function M.branch_name(worktree, as_path)
	local branch

	if worktree then
		branch = vim.fn.system(
			string.format(
				"git --git-dir=%s --work-tree=%s branch --show-current 2> /dev/null | tr -d '\n'",
				worktree.gitdir,
				worktree.toplevel
			)
		)
	elseif as_path then
		branch = vim.fn.system(string.format("git -C %s branch --show-current 2> /dev/null | tr -d '\n'", as_path))
	else
		branch = vim.fn.system("git branch --show-current 2> /dev/null | tr -d '\n'")
	end

	return branch
end

return M
