local blink = require("blink.cmp")

local vue_ls_config = {
	on_init = function(client)
		client.handlers["tsserver/request"] = function(_, result, context)
			local clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })
			if #clients == 0 then
				vim.notify(
					"Could not find `vtsls` lsp client, `vue_ls` would not work without it.",
					vim.log.levels.ERROR
				)
				return
			end
			local ts_client = clients[1]

			local param = unpack(result)
			local id, command, payload = unpack(param)
			ts_client:exec_cmd({
				title = "vue_request_forward", -- You can give title anything as it's used to represent a command in the UI, `:h Client:exec_cmd`
				command = "typescript.tsserverRequest",
				arguments = {
					command,
					payload,
				},
			}, { bufnr = context.bufnr }, function(_, r)
				local response_data = { { id, r.body } }
				---@diagnostic disable-next-line: param-type-mismatch
				client:notify("tsserver/response", response_data)
			end)
		end
	end,
	capabilities = vim.tbl_deep_extend(
		"force",
		{},
		vim.lsp.protocol.make_client_capabilities(),
		blink.get_lsp_capabilities()
	),
}

return vue_ls_config

-- Function to get TypeScript SDK path (prefer local, fallback to global)
-- local function get_typescript_sdk()
-- 	local local_sdk = vim.fn.getcwd() .. "/node_modules/typescript/lib"
-- 	if vim.fn.isdirectory(local_sdk) == 1 then
-- 		return local_sdk
-- 	end
--
-- 	-- Try global installation
-- 	local global_root = vim.fn.system("npm root -g"):gsub("\n", ""):gsub("\r", "")
-- 	local global_sdk = global_root .. "/typescript/lib"
-- 	if vim.fn.isdirectory(global_sdk) == 1 then
-- 		return global_sdk
-- 	end
--
-- 	local vue_ls_typescript_path = vim.fn.expand("$MASON/packages")
-- 		.. "/vue-language-server"
-- 		.. "/node_modules/typescript/lib"
-- 	if vim.fn.isdirectory(vue_ls_typescript_path) == 1 then
-- 		return vue_ls_typescript_path
-- 	end
--
-- 	-- If both fail, return nil to let vue-language-server find it automatically
-- 	return nil
-- end

-- return {
-- 	-- cmd = { "vue-language-server", "--stdio" },
-- 	filetypes = { "vue" },
-- 	root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
-- 	init_options = {
-- 		vue = {
-- 			hybridMode = false, -- Disable for inlay hints support
-- 		},
-- 		-- Only set typescript config if we have a valid TypeScript installation
-- 		typescript = get_typescript_sdk() and {
-- 			tsdk = get_typescript_sdk(),
-- 		} or nil,
-- 	},
-- settings = {
-- 	typescript = {
-- 		inlayHints = {
-- 			enumMemberValues = {
-- 				enabled = true,
-- 			},
-- 			functionLikeReturnTypes = {
-- 				enabled = true,
-- 			},
-- 			propertyDeclarationTypes = {
-- 				enabled = true,
-- 			},
-- 			parameterTypes = {
-- 				enabled = true,
-- 				suppressWhenArgumentMatchesName = true,
-- 			},
-- 			variableTypes = {
-- 				enabled = true,
-- 			},
-- 		},
-- 	},
-- },
-- 	capabilities = vim.tbl_deep_extend(
-- 		"force",
-- 		{},
-- 		vim.lsp.protocol.make_client_capabilities(),
-- 		blink.get_lsp_capabilities()
-- 	),
-- }
