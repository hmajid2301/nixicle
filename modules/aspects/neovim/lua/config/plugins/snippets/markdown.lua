local luasnip = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = luasnip.s
local i = luasnip.insert_node

local function create_markdown_snippets()
	luasnip.add_snippets("markdown", {
		-- Hugo "notice" shortcode (used in the blog)
		s(
			"notice",
			fmt(
				[[
{{{{< notice type="{}" title="{}" >}}}}
{}
{{{{< /notice >}}}}]],
				{
					i(1, "info"),
					i(2, "Title"),
					i(3, "Body text"),
				}
			)
		),
	})
end

return {
	create_markdown_snippets = create_markdown_snippets,
}