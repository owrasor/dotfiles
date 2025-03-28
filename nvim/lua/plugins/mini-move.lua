return {
	{
		"echasnovski/mini.nvim",
		version = "*",
		event = "VeryLazy",
		opts = {},
		config = function()
			require("mini.move").setup({
				mappings = {
					-- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
					left = "<M-Left>",
					right = "<M-Right>",
					down = "<M-Down>",
					up = "<M-Up>",

					-- Move current line in Normal mode
					line_left = "<M-Left>",
					line_right = "<M-Right>",
					line_down = "<M-Down>",
					line_up = "<M-Up>",
				},
			})
		end,
	},
}
