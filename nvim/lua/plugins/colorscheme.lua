function ColorMyPencils(color)
	color = color or "rose-pine"
	vim.cmd.colorscheme(color)
end

return {
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

			-- ColorMyPencils("tokyonight")
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

			ColorMyPencils("rose-pine")
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		opts = {},
		config = function()
			-- load the colorscheme here
			require("catppuccin").setup({
				background = { -- :h background
					dark = "mocha",
				},
			})

			-- ColorMyPencils("catppuccin")
		end,
	},
	{
		"gambhirsharma/vesper.nvim",
		lazy = false,
		priority = 1000,
		name = "vesper",
		config = function()
			-- ColorMyPencils("vesper")
		end,
	},
}
