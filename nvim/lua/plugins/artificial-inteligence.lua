return {
	-- {
	-- 	"github/copilot.vim",
	-- },
	-- {
	-- 	"CopilotC-Nvim/CopilotChat.nvim",
	-- 	dependencies = {
	-- 		{ "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
	-- 		{ "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
	-- 	},
	-- 	build = "make tiktoken", -- Only on MacOS or Linux
	-- 	opts = {
	-- 		-- See Configuration section for options
	-- 	},
	-- 	keys = {
	-- 		{ "<leader>ac", ":CopilotChat<CR>", mode = "n", desc = "Chat With Copilot" },
	-- 		{ "<leader>ae", ":CopilotChatExplain<CR>", mode = "v", desc = "Explain Code" },
	-- 		{ "<leader>ar", ":CopilotChatReview<CR>", mode = "v", desc = "Review Code" },
	-- 		{ "<leader>af", ":CopilotChatFix<CR>", mode = "v", desc = "Fix Code Issues" },
	-- 		{ "<leader>ao", ":CopilotChatOptimize<CR>", mode = "v", desc = "Optimize Code" },
	-- 		{ "<leader>ad", ":CopilotChatDocs<CR>", mode = "v", desc = "Generate Docs" },
	-- 		{ "<leader>at", ":CopilotChatTests<CR>", mode = "v", desc = "Generate Tests" },
	-- 		{ "<leader>am", ":CopilotChatCommit<CR>", mode = "n", desc = "Generate Commit Message" },
	-- 		{ "<leader>as", ":CopilotChatCommit<CR>", mode = "v", desc = "Generate Commit for Selection" },
	-- 	},
	-- 	-- See Commands section for default commands if you want to lazy load on them
	-- },
	-- {
	-- 	"augmentcode/augment.vim",
	-- 	config = function()
	-- 		vim.g.augment_workspace_folders = {
	-- 			"/Users/owrasor/Code/aprovafacil/aprovafacil-webapp",
	-- 			"/Users/owrasor/Code/aprovafacil/aprovafacil-webserver",
	-- 			"/Users/owrasor/Code/aprovafacil/aprovafacil-serverjs",
	-- 			"/Users/owrasor/Code/aprovafacil/aprovafacil-infra-dev",
	-- 			"/Users/owrasor/Code/aprovafacil/aprovafacil-infra-ec2",
	-- 			"/Users/owrasor/Code/owrasor/personal-finances",
	-- 		}
	--
	-- 		local keymap = vim.keymap.set
	--
	-- 		-- Open the chat window
	-- 		keymap({ "n", "v" }, "<leader>ac", "<cmd>Augment chat<CR>", { desc = "Open Augment Chat" })
	--
	-- 		-- Toggle chat window visibility
	-- 		keymap("n", "<leader>at", "<cmd>Augment chat-toggle<CR>", { desc = "Toggle Augment Chat" })
	--
	-- 		-- (Optional) Start a new chat session
	-- 		keymap("n", "<leader>as", "<cmd>Augment chat-new<CR>", { desc = "Start Augment Chat" })
	-- 	end,
	-- },
	-- {
	-- 	"yetone/avante.nvim",
	-- 	event = "VeryLazy",
	-- 	version = false, -- Never set this value to "*"! Never!
	-- 	opts = {
	-- 		-- add any opts here
	-- 		-- for example
	-- 		provider = "openai",
	-- 		openai = {
	-- 			endpoint = "https://api.openai.com/v1",
	-- 			model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
	-- 			timeout = 30000, -- Timeout in milliseconds, increase this for reasoning models
	-- 			temperature = 0,
	-- 			max_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
	-- 			--reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
	-- 		},
	-- 	},
	-- 	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	-- 	build = "make",
	-- 	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	-- 	dependencies = {
	-- 		"nvim-treesitter/nvim-treesitter",
	-- 		"stevearc/dressing.nvim",
	-- 		"nvim-lua/plenary.nvim",
	-- 		"MunifTanjim/nui.nvim",
	-- 		--- The below dependencies are optional,
	-- 		"echasnovski/mini.pick", -- for file_selector provider mini.pick
	-- 		"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
	-- 		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
	-- 		"ibhagwan/fzf-lua", -- for file_selector provider fzf
	-- 		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
	-- 		"zbirenbaum/copilot.lua", -- for providers='copilot'
	-- 		{
	-- 			-- support for image pasting
	-- 			"HakonHarnes/img-clip.nvim",
	-- 			event = "VeryLazy",
	-- 			opts = {
	-- 				-- recommended settings
	-- 				default = {
	-- 					embed_image_as_base64 = false,
	-- 					prompt_for_file_name = false,
	-- 					drag_and_drop = {
	-- 						insert_mode = true,
	-- 					},
	-- 					-- required for Windows users
	-- 					use_absolute_path = true,
	-- 				},
	-- 			},
	-- 		},
	-- 		{
	-- 			-- Make sure to set this up properly if you have lazy=true
	-- 			"MeanderingProgrammer/render-markdown.nvim",
	-- 			opts = {
	-- 				file_types = { "markdown", "Avante" },
	-- 			},
	-- 			ft = { "markdown", "Avante" },
	-- 		},
	-- 	},
	-- },
}
