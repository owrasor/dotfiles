function ColorMyPencils(color)
	color = color or "rose-pine"
	vim.cmd.colorscheme(color)
end

return {
	{
		{
			"folke/tokyonight.nvim",
			name = "tokyonight",
			lazy = false,
			priority = 1000,
			opts = {},
			config = function()
				-- load the colorscheme here
				require("tokyonight").setup({
					style = "night",
					transparent = true,
					terminal_colors = true,
					styles = {
						comments = { italic = false },
						keywords = { italic = false },
						sidebars = "dark",
						floats = "dark",
					},
				})
			end,
		},
		{
			"rose-pine/neovim",
			name = "rose-pine",
			lazy = false,
			priority = 1000,
			opts = {},
			config = function()
				require("rose-pine").setup({ disable_background = true })

				ColorMyPencils("tokyonight")
				-- load the colorscheme here
			end,
		},
	},
}
