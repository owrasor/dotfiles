return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-tree/nvim-web-devicons",
			"folke/todo-comments.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					path_display = { "smart" },
					mappings = {
						i = {
							["<C-k>"] = actions.move_selection_previous, -- move to prev result
							["<C-j>"] = actions.move_selection_next, -- move to next result
						},
					},
				},
			})

			telescope.load_extension("fzf")

			-- set keymaps
			local keymap = vim.keymap -- for conciseness
			local builtin = require("telescope.builtin")
			keymap.set("n", "<leader>f", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
			keymap.set("n", "<leader>o", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
			-- keymap.set("n", "<leader>/", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
			keymap.set(
				"n",
				"<leader>sc",
				"<cmd>Telescope grep_string<cr>",
				{ desc = "Find string under cursor in cwd" }
			)
			keymap.set("n", "<C-t>", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
			keymap.set("n", "<leader>ss", builtin.lsp_document_symbols, { desc = "Find symbols" })
			keymap.set("n", "<leader>sb", builtin.buffers, { desc = "Find Buffers" })
			keymap.set("n", "<leader>re", builtin.lsp_references, { desc = "Find references" })

			require("config.telescope.multigrep").setup()
		end,
	},
	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}
