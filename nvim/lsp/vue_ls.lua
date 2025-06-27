local vue_ls_typescript_path = vim.fn.expand("$MASON/packages")
	.. "/vue-language-server"
	.. "/node_modules/typescript/lib"

local vue_ls_config = {
	-- cmd = { "npm", "vue-language-server", "--stdio" },
	filetypes = { "vue" },
	init_options = {
		typescript = {
			-- Verificar uma forma de pegar o caminho sem a necessidade de informar o fullpath do mason
			tsdk = vue_ls_typescript_path,
		},
		vue = {
			hybridMode = false,
		},
	},
}

-- local vue_ls_config = {
-- 	on_init = function(client)
-- 		client.handlers["tsserver/request"] = function(_, result, context)
-- 			local clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })
-- 			if #clients == 0 then
-- 				vim.notify(
-- 					"Could not found `vtsls` lsp client, vue_lsp would not work without it.",
-- 					vim.log.levels.ERROR
-- 				)
-- 				return
-- 			end
-- 			local ts_client = clients[1]
--
-- 			vim.notify(ts_client.name .. " is handling the request", vim.log.levels.INFO)
--
-- 			local param = unpack(result)
-- 			local id, command, payload = unpack(param)
--
-- 			vim.notify(command .. " " .. id, vim.log.levels.INFO)
--
-- 			ts_client:exec_cmd({
-- 				title = "Vue Language Server Request",
-- 				command = "typescript.tsserverRequest",
-- 				arguments = {
-- 					command,
-- 					payload,
-- 				},
-- 			}, { bufnr = context.bufnr }, function(_, r)
-- 				local response_data = { { id, r.body } }
-- 				---@diagnostic disable-next-line: param-type-mismatch
-- 				client:notify("tsserver/response", response_data)
-- 			end)
-- 		end
-- 	end,
-- }

-- nvim 0.11 or above
vim.lsp.config("vue_ls", vue_ls_config)
