local ls = require("luasnip")
local s = ls.snippet
--local t = ls.text_node
local i = ls.insert_node
--local rep = require('luasnip.extras').rep
local fmt = require("luasnip.extras.fmt").fmt

return {
	s(
		"option",
		fmt(
			[[
                {} = mkOption {{
                  description = "{}";
                  type = types.{};
                }};
            ]],
			{ i(1), i(2), i(3, "str") }
		)
	),
}
