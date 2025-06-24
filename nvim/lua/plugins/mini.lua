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
					down = "<M-Down>",
					up = "<M-Up>",

					-- Move current line in Normal mode
					line_down = "<M-Down>",
					line_up = "<M-Up>",
				},
			})
		end,
	},
}
