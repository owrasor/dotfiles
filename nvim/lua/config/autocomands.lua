local keymap = vim.keymap -- for conciseness
local api = vim.api

-- Highlight on yank
api.nvim_create_autocmd("TextYankPost", {
	callback = function()
		vim.highlight.on_yank()
	end,
})

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
		keymap.set({ "n", "v" }, "<leader>ga", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

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
-- Change the Diagnostic symbols in the sign column (gutter)
-- (not in youtube nvim video)
local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
for type, icon in pairs(signs) do
	local hl = "DiagnosticSign" .. type
	vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- Ensure both vtsls and vue-ls are started for Vue files
api.nvim_create_autocmd("FileType", {
	pattern = "vue",
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()

		-- Check if vtsls is already attached
		local vtsls_clients = vim.lsp.get_clients({ bufnr = bufnr, name = "vtsls" })
		if #vtsls_clients == 0 then
			-- Force start vtsls for this buffer
			vim.defer_fn(function()
				-- TODO: Descobrir uma forma de buscar estes dados diretamente das configurações de vtsls
				-- Get vtsls config directly
				local function get_vue_language_server_path()
					local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"
					local vue_ls_path = mason_packages .. "/vue-language-server/node_modules/@vue/language-server"

					if vim.fn.isdirectory(vue_ls_path) == 1 then
						return vue_ls_path
					end

					local mason_env_path =
						vim.fn.expand("$MASON/packages/vue-language-server/node_modules/@vue/language-server")
					if vim.fn.isdirectory(mason_env_path) == 1 then
						return mason_env_path
					end

					return vue_ls_path
				end

				local vue_language_server_path = get_vue_language_server_path()
				local blink = require("blink.cmp")

				local vue_plugin = {
					name = "@vue/typescript-plugin",
					location = vue_language_server_path,
					languages = { "vue" },
					configNamespace = "typescript",
				}

				vim.lsp.start({
					name = "vtsls",
					cmd = { "vtsls", "--stdio" },
					filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
					root_dir = vim.fs.dirname(
						vim.fs.find({ "package.json", "tsconfig.json", "jsconfig.json", ".git" }, { upward = true })[1]
					),
					settings = {
						vtsls = {
							tsserver = {
								globalPlugins = {
									vue_plugin,
								},
							},
						},
					},
					capabilities = vim.tbl_deep_extend(
						"force",
						{},
						vim.lsp.protocol.make_client_capabilities(),
						blink.get_lsp_capabilities()
					),
				})
			end, 100)
		end
	end,
})
