return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"theHamsta/nvim-dap-virtual-text",
			"nvim-neotest/nvim-nio",
			"williamboman/mason.nvim",
		},
		config = function()
			local dap = require("dap")
			local ui = require("dapui")

			require("dapui").setup()
			require("nvim-dap-virtual-text").setup({})

			-- Handled by nvim-dap-go
			-- dap.adapters.go = {
			--   type = "server",
			--   port = "${port}",
			--   executable = {
			--     command = "dlv",
			--     args = { "dap", "-l", "127.0.0.1:${port}" },
			--   },
			-- }

			-- local elixir_ls_debugger = vim.fn.exepath("elixir-ls-debugger")
			-- if elixir_ls_debugger ~= "" then
			-- 	dap.adapters.mix_task = {
			-- 		type = "executable",
			-- 		command = elixir_ls_debugger,
			-- 	}
			--
			-- 	dap.configurations.elixir = {
			-- 		{
			-- 			type = "mix_task",
			-- 			name = "phoenix server",
			-- 			task = "phx.server",
			-- 			request = "launch",
			-- 			projectDir = "${workspaceFolder}",
			-- 			exitAfterTaskReturns = false,
			-- 			debugAutoInterpretAllModules = false,
			-- 		},
			-- 	}
			-- end
			--

			dap.adapters.php = {
				type = "executable",
				command = "node",
				args = { "/Users/owrasor/Code/xdebug/out/phpDebug.js" },
			}

			dap.configurations.php = {
				{
					type = "php",
					request = "launch",
					name = "Listen for Xdebug",
					port = 9003,
					pathMappings = {
						["/var/www/html/aprovafacil-webserver/"] = "${workspaceFolder}",
					},
				},
			}

			vim.keymap.set("n", "<leader>bb", dap.toggle_breakpoint)
			vim.keymap.set("n", "<leader>gb", dap.run_to_cursor)

			-- Eval var under cursor
			vim.keymap.set("n", "<space>?", function()
				require("dapui").eval(nil, { enter = true })
			end)

			vim.keymap.set("n", "<F5>", dap.continue)
			vim.keymap.set("n", "<F7>", dap.step_into)
			vim.keymap.set("n", "<F8>", dap.step_over)
			vim.keymap.set("n", "<F4>", dap.step_out)
			vim.keymap.set("n", "<F9>", dap.restart)
			vim.keymap.set("n", "<F10>", function()
				dap.terminate()
				ui.close()
			end)

			dap.listeners.before.attach.dapui_config = function()
				ui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				ui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				ui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				ui.close()
			end
		end,
	},
}
-- ---@param config {args?:string[]|fun():string[]?}
-- local function get_args(config)
-- 	local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
-- 	config = vim.deepcopy(config)
-- 	---@cast args string[]
-- 	config.args = function()
-- 		local new_args = vim.fn.input("Run with args: ", table.concat(args, " ")) --[[@as string]]
-- 		return vim.split(vim.fn.expand(new_args) --[[@as string]], " ")
-- 	end
-- 	return config
-- end
--
-- return {
-- 	{
-- 		"mfussenegger/nvim-dap",
-- 		recommended = true,
-- 		desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",
--
-- 		dependencies = {
-- 			"rcarriga/nvim-dap-ui",
-- 			-- virtual text for the debugger
-- 			{
-- 				"theHamsta/nvim-dap-virtual-text",
-- 				opts = {},
-- 			},
-- 		},
--
--     -- stylua: ignore
--     keys = {
--       { "<leader>d", "", desc = "+debug", mode = {"n", "v"} },
--       { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
--       { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
--       { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
--       { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
--       { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
--       { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
--       { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
--       { "<leader>dj", function() require("dap").down() end, desc = "Down" },
--       { "<leader>dk", function() require("dap").up() end, desc = "Up" },
--       { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
--       { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
--       { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
--       { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
--       { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
--       { "<leader>ds", function() require("dap").session() end, desc = "Session" },
--       { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
--       { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
--     },
--
-- 		config = function()
-- 			-- load mason-nvim-dap here, after all adapters have been setup
-- 			if LazyVim.has("mason-nvim-dap.nvim") then
-- 				require("mason-nvim-dap").setup(LazyVim.opts("mason-nvim-dap.nvim"))
-- 			end
--
-- 			vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
--
-- 			for name, sign in pairs(LazyVim.config.icons.dap) do
-- 				sign = type(sign) == "table" and sign or { sign }
-- 				vim.fn.sign_define(
-- 					"Dap" .. name,
-- 					{ text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
-- 				)
-- 			end
--
-- 			-- setup dap config by VsCode launch.json file
-- 			local vscode = require("dap.ext.vscode")
-- 			local json = require("plenary.json")
-- 			vscode.json_decode = function(str)
-- 				return vim.json.decode(json.json_strip_comments(str))
-- 			end
--
-- 			-- Extends dap.configurations with entries read from .vscode/launch.json
-- 			if vim.fn.filereadable(".vscode/launch.json") then
-- 				vscode.load_launchjs()
-- 			end
-- 		end,
-- 	},
--
-- 	-- fancy UI for the debugger
-- 	{
-- 		"rcarriga/nvim-dap-ui",
-- 		dependencies = { "nvim-neotest/nvim-nio" },
--     -- stylua: ignore
--     keys = {
--       { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
--       { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
--     },
-- 		opts = {},
-- 		config = function(_, opts)
-- 			local dap = require("dap")
-- 			local dapui = require("dapui")
-- 			dapui.setup(opts)
-- 			dap.listeners.after.event_initialized["dapui_config"] = function()
-- 				dapui.open({})
-- 			end
-- 			dap.listeners.before.event_terminated["dapui_config"] = function()
-- 				dapui.close({})
-- 			end
-- 			dap.listeners.before.event_exited["dapui_config"] = function()
-- 				dapui.close({})
-- 			end
-- 		end,
-- 	},
--
-- 	-- mason.nvim integration
-- 	{
-- 		"jay-babu/mason-nvim-dap.nvim",
-- 		dependencies = "mason.nvim",
-- 		cmd = { "DapInstall", "DapUninstall" },
-- 		opts = {
-- 			-- Makes a best effort to setup the various debuggers with
-- 			-- reasonable debug configurations
-- 			automatic_installation = true,
--
-- 			-- You can provide additional configuration to the handlers,
-- 			-- see mason-nvim-dap README for more information
-- 			handlers = {},
--
-- 			-- You'll need to check that you have the required things installed
-- 			-- online, please don't ask me how to install them :)
-- 			ensure_installed = {
-- 				-- Update this to ensure that you have the debuggers for the langs you want
-- 			},
-- 		},
-- 		-- mason-nvim-dap is loaded when nvim-dap loads
-- 		config = function() end,
-- 	},
-- }
