local luasnip = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = luasnip.s
local i = luasnip.insert_node
local t = luasnip.text_node
local sn = luasnip.snippet_node

local function create_go_snippets()
	luasnip.add_snippets("go", {
		-- Table-driven test snippet
		s(
			"ttest",
			fmt(
				[[
func Test{}(t *testing.T) {{
    tests := []struct {{
{}
    }}{{
{}
    }}
    for _, tt := range tests {{
        t.Run(tt.name, func(t *testing.T) {{
{}
        }})
    }}
}}
                ]],
				{
					i(1, "FunctionName"),
					-- Struct fields
					sn(2, {
						t({ "        name string", "        " }),
						i(1, "input int"),
						t({ "", "        " }),
						i(2, "want int"),
					}),
					-- Test cases
					sn(3, {
						t({ "        {name: " }),
						i(1, '"test case"'),
						t({ ", input: " }),
						i(2, "0"),
						t({ ", want: " }),
						i(3, "0"),
						t({ "}," }),
					}),
					-- Test implementation with require.NoError
					sn(4, {
						t({ "        got, err := " }),
						i(5, "FunctionUnderTest"),
						t({
							"(tt.input)",
							"        require.NoError(t, err)",
							"        if got != tt.want {",
							'            t.Errorf("got %v, want %v", got, tt.want)',
							"        }",
						}),
					}),
				}
			)
		),

		-- Single t.Run test snippet
		s(
			"trun",
			fmt(
				[[
func Test{}(t *testing.T) {{
    t.Run("{}", func(t *testing.T) {{
{}
    }})
}}
                ]],
				{
					i(1, "FunctionName"),
					i(2, "test scenario"),
					sn(3, {
						t({ "        // Test implementation", "        got, err := " }),
						i(4, "FunctionUnderTest"),
						t({ "()", "        require.NoError(t, err)" }),
						t({ "        if got != expected {" }),
						t({ '            t.Errorf("got %v, want %v", got, expected)' }),
						t({ "        }" }),
					}),
				}
			)
		),
	})
end

return {
	create_go_snippets = create_go_snippets,
}
