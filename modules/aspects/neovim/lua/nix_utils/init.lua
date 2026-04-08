-- Replacement for lua/nixCatsUtils/ — bridges nix-wrapper-modules nixInfo global.
-- nixInfo is set up in init.lua as a global before this module is used.
local M = {}

local nixInfo = _G.nixInfo or function(default, ...)
	return default
end

M.isNix = vim.g.nix_info_plugin_name ~= nil

--- Get the filesystem path of a nix-installed plugin by name.
--- Falls back to searching runtimepath when not running under nix.
---@param name string
---@return string|nil
function M.get_nix_plugin_path(name)
	if M.isNix then
		return nixInfo(nil, "plugins", "lazy", name) or nixInfo(nil, "plugins", "start", name)
	else
		return vim.api.nvim_get_runtime_file("pack/*/*/" .. name, false)[1]
	end
end

--- lze handler: enable/disable a plugin spec based on a spec (category) name.
--- Usage in lze specs:
---   for_cat = "specname"                   -- enable if spec is enabled
---   for_cat = { cat = "specname", default = true }  -- with non-nix fallback
M.for_cat_handler = {
	spec_field = "for_cat",
	set_lazy = false,
	modify = function(plugin)
		if M.isNix then
			if type(plugin.for_cat) == "table" then
				plugin.enabled = nixInfo(plugin.for_cat.default, "settings", "cats", plugin.for_cat.cat)
			elseif type(plugin.for_cat) == "string" then
				plugin.enabled = nixInfo(false, "settings", "cats", plugin.for_cat)
			end
		end
		return plugin
	end,
}

return M
