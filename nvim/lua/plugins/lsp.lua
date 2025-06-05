return {
	{
		"williamboman/mason.nvim",
		tag = "v1.11.0",
		dependencies = {
			{ "williamboman/mason-lspconfig.nvim", tag = "v1.32.0" },
			"WhoIsSethDaniel/mason-tool-installer.nvim",
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
				automatic_installation = true,
				-- list of servers for mason to install
				ensure_installed = {
					"ts_ls",
					"volar",
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
	-- {
	-- 	"hrsh7th/nvim-cmp",
	-- 	event = "InsertEnter",
	-- 	dependencies = {
	-- 		"hrsh7th/cmp-buffer", -- source for text in buffer
	-- 		"hrsh7th/cmp-path", -- source for file system paths
	-- 		{
	-- 			"L3MON4D3/LuaSnip",
	-- 			-- follow latest release.
	-- 			version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
	-- 			-- install jsregexp (optional!).
	-- 			build = "make install_jsregexp",
	-- 		},
	-- 		"saadparwaiz1/cmp_luasnip", -- for autocompletion
	-- 		"rafamadriz/friendly-snippets", -- useful snippets
	-- 		"onsails/lspkind.nvim", -- vs-code like pictograms
	-- 	},
	-- 	config = function()
	-- 		local cmp = require("cmp")
	--
	-- 		local luasnip = require("luasnip")
	--
	-- 		local lspkind = require("lspkind")
	--
	-- 		-- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
	-- 		require("luasnip.loaders.from_vscode").lazy_load()
	-- 		require("luasnip.loaders.from_snipmate").lazy_load({ paths = { vim.fn.stdpath("config") .. "/snippets" } })
	--
	-- 		local has_words_before = function()
	-- 			local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	-- 			return col ~= 0
	-- 				and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
	-- 		end
	--
	-- 		cmp.setup({
	-- 			completion = {
	-- 				completeopt = "menu,menuone,preview,noselect",
	-- 			},
	-- 			snippet = { -- configure how nvim-cmp interacts with snippet engine
	-- 				expand = function(args)
	-- 					luasnip.lsp_expand(args.body)
	-- 				end,
	-- 			},
	-- 			window = {
	-- 				completion = cmp.config.window.bordered(),
	-- 				documentation = cmp.config.window.bordered(),
	-- 			},
	-- 			mapping = cmp.mapping.preset.insert({
	-- 				["<C-Tab>"] = cmp.mapping(function(fallback)
	-- 					if cmp.visible() then
	-- 						cmp.select_next_item()
	-- 					elseif luasnip.locally_jumpable(1) then
	-- 						luasnip.jump(1)
	-- 					elseif has_words_before() then
	-- 						cmp.complete()
	-- 						print("complete...")
	-- 					else
	-- 						fallback()
	-- 					end
	-- 				end, { "i", "s" }),
	-- 				["<S-Tab>"] = cmp.mapping(function(fallback)
	-- 					if cmp.visible() then
	-- 						cmp.select_prev_item()
	-- 					elseif luasnip.locally_jumpable(-1) then
	-- 						luasnip.jump(-1)
	-- 					else
	-- 						fallback()
	-- 					end
	-- 				end, { "i", "s" }),
	-- 				["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
	-- 				["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
	-- 				["<C-b>"] = cmp.mapping.scroll_docs(-4),
	-- 				["<C-f>"] = cmp.mapping.scroll_docs(4),
	-- 				["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
	-- 				["<C-e>"] = cmp.mapping.abort(), -- close completion window
	-- 				["<CR>"] = cmp.mapping.confirm({ select = true }),
	-- 			}),
	-- 			-- sources for autocompletion
	-- 			sources = cmp.config.sources({
	-- 				{ name = "nvim_lsp" },
	-- 				{ name = "luasnip" }, -- snippets
	-- 				{ name = "buffer" }, -- text within current buffer
	-- 				{ name = "path" }, -- file system paths
	-- 			}),
	--
	-- 			-- configure lspkind for vs-code like pictograms in completion menu
	-- 			formatting = {
	-- 				format = lspkind.cmp_format({
	-- 					maxwidth = 50,
	-- 					ellipsis_char = "...",
	-- 				}),
	--
	-- 				fields = { "kind", "abbr", "menu" },
	-- 				expandable_indicator = true,
	-- 			},
	-- 		})
	-- 	end,
	-- },
	{
		"neovim/nvim-lspconfig",
		-- tag = "v0.1.8",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			{ "antosha417/nvim-lsp-file-operations", config = true },
			{ "folke/neodev.nvim", opts = {} },
			"hrsh7th/nvim-cmp",
			"jayp0521/mason-null-ls.nvim",
			"nvimtools/none-ls.nvim",
			"nvimtools/none-ls-extras.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			-- import lspconfig plugin
			local lspconfig = require("lspconfig")

			-- import mason_lspconfig plugin
			local mason_lspconfig = require("mason-lspconfig")

			-- import cmp-nvim-lsp plugin
			-- local cmp_nvim_lsp = require("cmp_nvim_lsp")

			local keymap = vim.keymap -- for conciseness

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					-- Buffer local mappings.
					-- See `:help vim.lsp.*` for documentation on any of the below functions
					local opts = { buffer = ev.buf, silent = true }

					-- set keybinds
					opts.desc = "Show LSP references"
					keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

					opts.desc = "Go to declaration"
					keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

					opts.desc = "Show LSP definitions"
					keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

					opts.desc = "Show LSP implementations"
					keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

					opts.desc = "Show LSP type definitions"
					keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

					opts.desc = "See available code actions"
					keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

					opts.desc = "Smart rename"
					keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

					opts.desc = "Show buffer diagnostics"
					keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

					opts.desc = "Show line diagnostics"
					keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

					opts.desc = "Go to previous diagnostic"
					keymap.set("n", "[d", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, opts) -- jump to previous diagnostic in buffer

					opts.desc = "Go to next diagnostic"
					keymap.set("n", "]d", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, opts) -- jump to next diagnostic in buffer

					opts.desc = "Show documentation for what is under cursor"
					keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

					opts.desc = "Restart LSP"
					keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
				end,
			})

			-- used to enable autocompletion (assign to every lsp server config)
			-- local capabilities = cmp_nvim_lsp.default_capabilities()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- Change the Diagnostic symbols in the sign column (gutter)
			-- (not in youtube nvim video)
			local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
			for type, icon in pairs(signs) do
				local hl = "DiagnosticSign" .. type
				vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
			end

			mason_lspconfig.setup_handlers({
				-- default handler for installed servers
				function(server_name)
					lspconfig[server_name].setup({
						capabilities = capabilities,
					})
				end,
				["svelte"] = function()
					-- configure svelte server
					lspconfig["svelte"].setup({
						capabilities = capabilities,
						on_attach = function(client)
							vim.api.nvim_create_autocmd("BufWritePost", {
								pattern = { "*.js", "*.ts" },
								callback = function(ctx)
									-- Here use ctx.match instead of ctx.file
									client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
								end,
							})
						end,
					})
				end,
				["graphql"] = function()
					-- configure graphql language server
					lspconfig["graphql"].setup({
						capabilities = capabilities,
						filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
					})
				end,
				["emmet_ls"] = function()
					-- configure emmet language server
					lspconfig["emmet_ls"].setup({
						capabilities = capabilities,
						filetypes = {
							"html",
							"typescriptreact",
							"javascriptreact",
							"css",
							"sass",
							"scss",
							"less",
							"svelte",
						},
					})
				end,
				["lua_ls"] = function()
					-- configure lua server (with special settings)
					lspconfig["lua_ls"].setup({
						capabilities = capabilities,
						settings = {
							Lua = {
								-- make the language server recognize "vim" global
								diagnostics = {
									globals = { "vim" },
								},
								completion = {
									callSnippet = "Replace",
								},
							},
						},
					})
				end,
				["intelephense"] = function()
					lspconfig["intelephense"].setup({
						commands = {
							IntelephenseIndex = {
								function()
									vim.lsp.buf.execute_command({ command = "intelephense.index.workspace" })
								end,
							},
						},
						on_attach = function(client, _)
							client.server_capabilities.documentFormattingProvider = false
							client.server_capabilities.documentRangeFormattingProvider = false
						end,
						capabilities = capabilities,
					})
				end,
				["ts_ls"] = function()
					local mason_registry = require("mason-registry")
					local vue_language_server_path = mason_registry
						.get_package("vue-language-server")
						:get_install_path() .. "/node_modules/@vue/language-server"

					lspconfig["ts_ls"].setup({
						init_options = {
							plugins = {
								{
									name = "@vue/typescript-plugin",
									location = vue_language_server_path,
									languages = { "vue" },
								},
							},
						},
						filetypes = {
							"typescript",
							"javascript",
							"javascriptreact",
							"typescriptreact",
							"vue",
						},
						capabilities = capabilities,
					})
				end,
				["volar"] = function()
					local mason_registry = require("mason-registry")
					local ts_language_server_path = mason_registry.get_package("vue-language-server"):get_install_path()
						.. "/node_modules/typescript/lib"

					lspconfig["volar"].setup({
						init_options = {
							typescript = {
								tsdk = ts_language_server_path,
							},
							vue = {
								hybridMode = false,
							},
						},
						filetypes = { "vue" },
						capabilities = capabilities,
					})
				end,
			})
		end,
	},
}
