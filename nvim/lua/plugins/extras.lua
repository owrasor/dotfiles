return {
	{ "numToStr/Comment.nvim", opts = {}, lazy = false },
	{ "joosepalviste/nvim-ts-context-commentstring", lazy = true },
	{
		"stevearc/dressing.nvim",
		dependencies = { "MunifTanjim/nui.nvim" },
		opts = {},
		config = function()
			require("dressing").setup()
		end,
	},
	{
		"christoomey/vim-tmux-navigator",
	},
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })

			require("mini.surround").setup()

			require("mini.pairs").setup()

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
	{
		"ThePrimeagen/harpoon",
		dependencies = { "nvim-lua/plenary.nvim" },
		lazy = true,
		keys = {
			{ "<leader>ha", "<cmd>lua require('harpoon.mark').add_file()<CR>", desc = "Add file to harpoon" },
			{ "<leader>hh", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>", desc = "Toggle harpoon menu" },
			{ "<leader>h1", "<cmd>lua require('harpoon.ui').nav_file(1)<CR>", desc = "Navigate to file 1" },
			{ "<leader>h2", "<cmd>lua require('harpoon.ui').nav_file(2)<CR>", desc = "Navigate to file 2" },
			{ "<leader>h3", "<cmd>lua require('harpoon.ui').nav_file(3)<CR>", desc = "Navigate to file 3" },
			{ "<leader>h4", "<cmd>lua require('harpoon.ui').nav_file(4)<CR>", desc = "Navigate to file 4" },
		},
	},
	{
		"voldikss/vim-floaterm",
		keys = {
			{ "<F1>", ":FloatermToggle<CR>" },
			{ "<F1>", "<Esc>:FloatermToggle<CR>", mode = "i" },
			{ "<F1>", "<C-\\><C-n>:FloatermToggle<CR>", mode = "t" },
		},
		cmd = { "FloatermToggle" },
		init = function()
			vim.g.floaterm_width = 0.8
			vim.g.floaterm_height = 0.8
		end,
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
		config = function()
			require("neo-tree").setup({})

			local keymap = vim.keymap -- for conciseness
			keymap.set(
				"n",
				"<leader>e",
				"<cmd>Neotree reveal=true position=float toggle<cr>",
				{ desc = "Open or Close explorer" }
			)
		end,
	},
}
