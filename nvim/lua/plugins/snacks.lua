return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		dashboard = { enabled = true },
		indent = {
			enabled = true,
			scope = { enabled = false }, -- Desabilita a linha guia (risco) do escopo atual
		},
		picker = {
			enabled = true,
			sources = {
				files = { hidden = true },
			},
		},
		quickfile = { enabled = true },
		words = { enabled = true },
		styles = {},
	},
	keys = {
		-- find
		{
			"<leader>sp",
			function()
				Snacks.picker.projects()
			end,
			desc = "Projects",
		},
		{
			"<leader>d",
			function()
				Snacks.picker.diagnostics()
			end,
			desc = "Diagnostics",
		},
		{
			"<leader>D",
			function()
				Snacks.picker.diagnostics_buffer()
			end,
			desc = "Buffer Diagnostics",
		},
		{
			"<leader>sh",
			function()
				Snacks.picker.help()
			end,
			desc = "Help Pages",
		},
		{
			"<leader>si",
			function()
				Snacks.picker.icons()
			end,
			desc = "Icons",
		},
		{
			"<leader>sk",
			function()
				Snacks.picker.keymaps()
			end,
			desc = "Keymaps",
		},
		{
			"<F1>",
			function()
				Snacks.terminal.toggle(nil, { win = { position = "bottom", height = 0.4 } })
			end,
			desc = "Toggle Terminal",
			mode = { "n", "t", "i" },
		},
	},
}
