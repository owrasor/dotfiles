return {
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = {
			"DBUI",
			"DBUIToggle",
			"DBUIAddConnection",
			"DBUIFindBuffer",
		},
		init = function()
			-- Your DBUI configuration
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
	{ -- optional saghen/blink.cmp completion source
		"saghen/blink.cmp",
		version = "1.*",
		opts = {
			completion = {
				list = {
					selection = {
						preselect = true,
						auto_insert = true,
					},
				},
			},
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
				per_filetype = {
					sql = { "snippets", "dadbod", "buffer" },
				},
				-- add vim-dadbod-completion to your completion providers
				providers = {
					dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
				},
			},
			keymap = {
				-- set to 'none' to disable the 'default' preset
				preset = "default",

				["<Up>"] = { "select_prev", "fallback" },
				["<Down>"] = { "select_next", "fallback" },

				-- disable a keymap from the preset
				["<C-e>"] = {},

				-- show with a list of providers
				["<C-space>"] = {
					function(cmp)
						cmp.show({ providers = { "snippets" } })
					end,
				},
				["<cr>"] = { "accept", "fallback" },
			},
		},
	},
	-- {
	-- 	"kndndrj/nvim-dbee",
	-- 	dependencies = {
	-- 		"MunifTanjim/nui.nvim",
	-- 	},
	-- 	build = function()
	-- 		-- Install tries to automatically detect the install method.
	-- 		-- if it fails, try calling it with one of these parameters:
	-- 		--    "curl", "wget", "bitsadmin", "go"
	-- 		require("dbee").install()
	-- 	end,
	-- 	config = function()
	-- 		require("dbee").setup(--[[optional config]])
	-- 	end,
	-- },
}
