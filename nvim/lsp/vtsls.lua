-- Get the correct path for the Vue language server
local function get_vue_language_server_path()
	-- First try using Mason's packages directory
	local mason_packages = vim.fn.stdpath("data") .. "/mason/packages"
	local vue_ls_path = mason_packages .. "/vue-language-server/node_modules/@vue/language-server"

	-- Check if it exists, otherwise fallback to MASON env var
	if vim.fn.isdirectory(vue_ls_path) == 1 then
		return vue_ls_path
	end

	-- Fallback to MASON env var if set
	local mason_env_path = vim.fn.expand("$MASON/packages/vue-language-server/node_modules/@vue/language-server")
	if vim.fn.isdirectory(mason_env_path) == 1 then
		return mason_env_path
	end

	-- Last resort - return the Mason packages path anyway
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

local vtsls_config = {
	settings = {
		vtsls = {
			tsserver = {
				globalPlugins = {
					vue_plugin,
				},
			},
		},
	},
	filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
	capabilities = vim.tbl_deep_extend(
		"force",
		{},
		vim.lsp.protocol.make_client_capabilities(),
		blink.get_lsp_capabilities()
	),
}

return vtsls_config
