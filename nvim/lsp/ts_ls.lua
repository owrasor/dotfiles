vim.lsp.config("ts_ls", {
	init_options = {
		plugins = {
			{
				name = "@vue/typescript-plugin",
				-- Verificar uma forma de pegar o caminho sem a necessidade de informar o fullpath do mason
				location = "/Users/owrasor/.local/share/nvim/mason/packages/vue-language-server/node_modules/@vue/language-server",
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
})
