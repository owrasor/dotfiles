return {
	"akinsho/flutter-tools.nvim",
	lazy = false,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"stevearc/dressing.nvim", -- opcional, para melhorar a interface de seleção de emuladores
	},
	config = function()
		local blink_ok, blink = pcall(require, "blink.cmp")
		local capabilities = vim.lsp.protocol.make_client_capabilities()

		if blink_ok then
			capabilities = vim.tbl_deep_extend("force", {}, capabilities, blink.get_lsp_capabilities())
		end

		require("flutter-tools").setup({
			ui = {
				border = "rounded",
			},
			decorations = {
				statusline = {
					app_version = true,
					device = true,
				},
			},
			debugger = {
				enabled = true, -- Integração nativa com o nvim-dap que você já possui configurado
				run_via_dap = true,
			},
			lsp = {
				color = { -- Mostra as cores do Tailwind/Flutter diretamente no código
					enabled = true,
					background = false,
					foreground = false,
					virtual_text = true,
				},
				capabilities = capabilities,
			},
		})
	end,
}
