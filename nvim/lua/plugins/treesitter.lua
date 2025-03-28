return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	config = function()
		local configs = require("nvim-treesitter.configs")

		configs.setup({
			ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "php", "javascript", "html" },
			sync_install = false,
			highlight = { enable = true },
			indent = { enable = true },
			modules = {},
			auto_install = true,
			ignore_install = {},
		})
	end,
}
