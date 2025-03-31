local luasnip = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
local s = luasnip.s
local i = luasnip.insert_node

local function create_go_snippets()
	luasnip.add_snippets("go", {
		-- Table-driven test snippet
		s(
			{
				trig = "ttest",
				dscr = "Generate a Go table-driven test",
			},
			fmt(
				[[
        func Test{}(t *testing.T) {{
            tests := []struct {{
                name string
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
					i(2, "input  int\nwant  int"),
					i(
						3,
						[[{
                name:  "test-case-1",
                input: 42,
                want:  24,
            },]]
					),
					i(
						4,
						[[got := SomeFunction(tt.input)
            if got != tt.want {{
                t.Errorf("got %v, want %v", got, tt.want)
            }}]]
					),
				}
			)
		),

		-- Single t.Run test snippet
		s(
			{
				trig = "trun",
				dscr = "Generate a Go test with t.Run",
			},
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
					i(2, "test-scenario"),
					i(
						3,
						[[// Test implementation
            result := SomeFunction()
            if result != expected {{
                t.Error("unexpected result")
            }}]]
					),
				}
			)
		),
	})
end

return {
	create_go_snippets = create_go_snippets,
}
