return {
	cmd = "lua-language-server",
	filetypes = { "lua" },
	single_file_support = true,
	-- log_level = vim.lsp.protocol.MessageType.Warning,
	root_markers = {
		".luarc.json",
		".luacheckrc",
	},
}
