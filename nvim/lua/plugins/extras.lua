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
			-- Better Around/Inside textobjects
			--
			-- Examples:
			--  - va)  - [V]isually select [A]round [)]paren
			--  - yinq - [Y]ank [I]nside [N]ext [']quote
			--  - ci'  - [C]hange [I]nside [']quote
			require("mini.ai").setup({ n_lines = 500 })

			-- Add/delete/replace surroundings (brackets, quotes, etc.)
			--
			-- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
			-- - sd'   - [S]urround [D]elete [']quotes
			-- - sr)'  - [S]urround [R]eplace [)] [']
			require("mini.surround").setup()

			require("mini.pairs").setup()

			-- local statusline = require("mini.statusline")
			-- statusline.setup({
			--   use_icons = vim.g.have_nerd_font,
			-- })
			-- ---@diagnostic disable-next-line: duplicate-set-field
			-- statusline.section_location = function()
			--   return "%2l:%-2v"
			-- end
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
	-- {
	-- 	"voldikss/vim-floaterm",
	-- 	keys = {
	-- 		{ "<F1>", ":FloatermToggle<CR>" },
	-- 		{ "<F1>", "<Esc>:FloatermToggle<CR>", mode = "i" },
	-- 		{ "<F1>", "<C-\\><C-n>:FloatermToggle<CR>", mode = "t" },
	-- 	},
	-- 	cmd = { "FloatermToggle" },
	-- 	init = function()
	-- 		vim.g.floaterm_width = 0.8
	-- 		vim.g.floaterm_height = 0.8
	-- 	end,
	-- },
	{
		"ThePrimeagen/harpoon",
		dependencies = { "nvim-lua/plenary.nvim" },
		lazy = true,
		keys = {
			{ "<leader>ha", "<cmd>lua require('harpoon.mark').add_file()<CR>", desc = "Add file to harpoon" },
			{ "<leader>h", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>", desc = "Toggle harpoon menu" },
			{ "<leader>h1", "<cmd>lua require('harpoon.ui').nav_file(1)<CR>", desc = "Navigate to file 1" },
			{ "<leader>h2", "<cmd>lua require('harpoon.ui').nav_file(2)<CR>", desc = "Navigate to file 2" },
			{ "<leader>h3", "<cmd>lua require('harpoon.ui').nav_file(3)<CR>", desc = "Navigate to file 3" },
			{ "<leader>h4", "<cmd>lua require('harpoon.ui').nav_file(4)<CR>", desc = "Navigate to file 4" },
		},
	},
}
