return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = { "L3MON4D3/LuaSnip", version = "v2.*" },
		opts = {
			-- snippets = { preset = "luasnip" },
			completion = {
				list = {
					selection = {
						preselect = false,
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
						cmp.show({ providers = { "lsp", "path", "snippets", "buffer" } })
					end,
				},
				["<cr>"] = { "accept", "fallback" },
			},
		},
	},
	{
		"mason-org/mason.nvim",
		tag = "v2.0.0",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{
				"mason-org/mason-lspconfig.nvim",
				tag = "v2.0.0",
				dependencies = {
					{
						"neovim/nvim-lspconfig",
						dependencies = {
							{
								"folke/lazydev.nvim",
								ft = "lua", -- only load on lua files
								opts = {
									library = {
										-- See the configuration section for more details
										-- Load luvit types when the `vim.uv` word is found
										{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
									},
								},
							},
						},
					},
				},
			},
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "antosha417/nvim-lsp-file-operations", config = true },
			"saghen/blink.cmp",
		},
		config = function()
			-- import mason
			local mason = require("mason")

			-- import mason-lspconfig
			local mason_lspconfig = require("mason-lspconfig")

			local mason_tool_installer = require("mason-tool-installer")

			-- enable mason and configure icons
			mason.setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})

			mason_lspconfig.setup({
				automatic_enable = true,
				ensure_installed = {
					"ts_ls",
					-- "vtsls", -- vue typescript language server
					"vue_ls",
					"html",
					"cssls",
					"tailwindcss",
					"svelte",
					"lua_ls",
					"graphql",
					"emmet_ls",
					"prismals",
					"pyright",
				},
			})

			mason_tool_installer.setup({
				ensure_installed = {
					"prettier", -- prettier formatter
					"stylua", -- lua formatter
					"isort", -- python formatter
					"black", -- python formatter
					"pylint",
					"eslint_d",
				},
			})
		end,
	},
}
