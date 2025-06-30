return {
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
				automatic_enable = false,
				ensure_installed = {
					"ts_ls",
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
					"pint",
				},
			})
		end,
	},
}
