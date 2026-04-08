-- Bootstrap nixInfo global from the nix-wrapper-modules info plugin.
-- When loaded via nix, vim.g.nix_info_plugin_name is set to the info plugin name.
-- When loaded outside nix (e.g. bare nvim), we provide a fallback that returns defaults.
do
	local ok
	ok, _G.nixInfo = pcall(require, vim.g.nix_info_plugin_name)
	if not ok then
		-- Not running under nix-wrapper-modules — provide a no-op fallback.
		-- nixInfo(default, ...) always returns default.
		local fallback = setmetatable({}, {
			__call = function(_, default)
				return default
			end,
		})
		package.loaded[vim.g.nix_info_plugin_name or "nix-info"] = fallback
		_G.nixInfo = fallback
	end
	nixInfo.isNix = vim.g.nix_info_plugin_name ~= nil
end

require("config")
