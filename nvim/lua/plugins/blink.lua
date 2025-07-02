return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		dependencies = { "L3MON4D3/LuaSnip", version = "v2.*", "rafamadriz/friendly-snippets" },
		config = function()
			vim.cmd("highlight Pmenu guibg=none")
			vim.cmd("highlight PmenuExtra guibg=none")
			vim.cmd("highlight FloatBorder guibg=none")
			vim.cmd("highlight NormalFloat guibg=none")
			require("blink.cmp").setup({
				snippets = { preset = "luasnip" },
				signature = { enabled = true },
				appearance = {
					use_nvim_cmp_as_default = false,
					nerd_font_variant = "normal",
				},
				sources = {
					-- per_filetype = {
					--     codecompanion = { "codecompanion" },
					-- },
					default = { "laravel", "lazydev", "lsp", "path", "snippets", "buffer" },
					-- default = { "lazydev", "lsp", "path", "snippets", "buffer" },
					per_filetype = {
						sql = { "snippets", "dadbod", "buffer" },
					},
					providers = {
						-- 		-- add vim-dadbod-completion to your completion providers
						lazydev = {
							name = "LazyDev",
							module = "lazydev.integrations.blink",
							score_offset = 100,
						},
						laravel = {
							name = "laravel",
							module = "laravel.blink_source",
							enabled = function()
								return vim.bo.filetype == "php" or vim.bo.filetype == "blade"
							end,
							kind = "Laravel",
							score_offset = 1000, -- Highest priority
							min_keyword_length = 1,
						},
						dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
						cmdline = {
							min_keyword_length = 2,
						},
					},
				},
				keymap = {
					-- set to 'none' to disable the 'default' preset
					preset = "default",

					["<Up>"] = { "select_prev", "fallback" },
					["<Down>"] = { "select_next", "fallback" },

					-- disable a keymap from the preset
					["<C-e>"] = {},

					-- show with a list of providers
					["<C-space>"] = {
						function(cmp)
							cmp.show({ providers = { "lsp", "path", "snippets", "buffer" } })
						end,
					},
					["<cr>"] = { "accept", "fallback" },
				},
				cmdline = {
					enabled = false,
					completion = { menu = { auto_show = true } },
					keymap = {
						["<CR>"] = { "accept_and_enter", "fallback" },
					},
				},
				completion = {
					menu = {
						border = nil,
						scrolloff = 1,
						scrollbar = false,
						draw = {
							columns = {
								{ "kind_icon" },
								{ "label", "label_description", gap = 1 },
								{ "kind" },
								{ "source_name" },
							},
						},
					},
					documentation = {
						window = {
							border = nil,
							scrollbar = false,
							winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
						},
						auto_show = true,
						auto_show_delay_ms = 500,
					},
				},
			})

			require("luasnip.loaders.from_vscode").lazy_load()
		end,
		-- opts = {
		-- 	-- snippets = { preset = "luasnip" },
		-- 	completion = {
		-- 		list = {
		-- 			selection = {
		-- 				preselect = false,
		-- 				auto_insert = true,
		-- 			},
		-- 		},
		-- 	},
		-- 	sources = {
		-- 		default = { "lsp", "path", "snippets", "buffer" },
		-- 		per_filetype = {
		-- 			sql = { "snippets", "dadbod", "buffer" },
		-- 		},
		-- 		-- add vim-dadbod-completion to your completion providers
		-- 		providers = {
		-- 			dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
		-- 		},
		-- 	},
		-- 	keymap = {
		-- 		-- set to 'none' to disable the 'default' preset
		-- 		preset = "default",
		--
		-- 		["<Up>"] = { "select_prev", "fallback" },
		-- 		["<Down>"] = { "select_next", "fallback" },
		--
		-- 		-- disable a keymap from the preset
		-- 		["<C-e>"] = {},
		--
		-- 		-- show with a list of providers
		-- 		["<C-space>"] = {
		-- 			function(cmp)
		-- 				cmp.show({ providers = { "lsp", "path", "snippets", "buffer" } })
		-- 			end,
		-- 		},
		-- 		["<cr>"] = { "accept", "fallback" },
		-- 	},
		-- },
	},
}
