return {
	{
		"adibhanna/laravel.nvim",
		ft = { "php", "blade" },
		dependencies = {
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
		},
		keys = {
			{ "<leader>Lr", ":LaravelRoute<cr>", desc = "Laravel Routes" },
			{ "<leader>Lm", ":LaravelMake<cr>", desc = "Laravel Make" },
			{ "<leader>Ls", ":LaravelStatus<cr>", desc = "Laravel status" },
		},
		event = { "VeryLazy" },
		config = function()
			require("laravel").setup()
		end,
	},
	-- {
	--   dir = "~/Developer/opensource/phprefactoring.nvim",
	--   -- 'adibhanna/phprefactoring.nvim',
	--   dependencies = {
	--     'MunifTanjim/nui.nvim',
	--   },
	--   ft = 'php',
	--   config = function()
	--     require('phprefactoring').setup({
	--       ui = {
	--         use_floating_menu = true,
	--         border = 'rounded',
	--         width = 45,
	--       },
	--       refactor = {
	--         show_preview = true,
	--         confirm_destructive = true,
	--         auto_format = true,
	--       },
	--       lsp = {
	--         use_lsp_rename = true,
	--         preferred_clients = { 'intelephense', 'phpactor', 'psalm' },
	--       },
	--     })
	--   end,
	-- }
}
