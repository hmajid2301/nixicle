local ls = require("luasnip")
local s = ls.snippet
--local t = ls.text_node
local i = ls.insert_node
local rep = require("luasnip.extras").rep
local fmt = require("luasnip.extras.fmt").fmt

return {
	s(
		"errcheck",
		fmt(
			[[
      if err != nil {{
        return {}fmt.Errorf("{}: %w", err)
      }}
    ]],
			{
				i(1),
				i(2),
			}
		)
	),
	s(
		"gomega-noerror",
		fmt('Expect(err).ToNot(HaveOccurred(), "{}")', {
			i(1, "Should not have errored"),
		})
	),
	s(
		"ginkgo-boilerplate",
		fmt(
			[[
    package {}

    import (
      . "github.com/onsi/ginkgo/v2"
      . "github.com/onsi/gomega"
    )

    var _ = Describe("{}.{}", func() {{
      It("should run this", func() {{
        Expect(true).To(BeTrue())
      }})
    }})
  ]],
			{
				i(1),
				rep(1),
				i(2),
			}
		)
	),
}
