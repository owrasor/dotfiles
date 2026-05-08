local parsers = {
	"dart",
	"bash",
	"c",
	"html",
	"javascript",
	"json",
	"lua",
	"luadoc",
	"luap",
	"markdown",
	"markdown_inline",
	"python",
	"query",
	"regex",
	"tsx",
	"typescript",
	"vue",
	"vim",
	"vimdoc",
	"yaml",
	"proto",
	"php",
	"blade",
}

local function map(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

local function has_indent_query(lang)
	return #vim.api.nvim_get_runtime_file("queries/" .. lang .. "/indents.scm", false) > 0
end

local function ensure_parsers_installed()
	local ts = require("nvim-treesitter")
	local installed = ts.get_installed()
	local missing = vim.tbl_filter(function(parser)
		return not vim.list_contains(installed, parser)
	end, parsers)

	if #missing > 0 then
		ts.install(missing, { summary = true })
	end
end

local function setup_textobjects()
	require("nvim-treesitter-textobjects.config").update({
		select = {
			lookahead = true,
			selection_modes = {
				["@parameter.outer"] = "v",
				["@parameter.inner"] = "v",
				["@function.outer"] = "v",
				["@conditional.outer"] = "V",
				["@loop.outer"] = "V",
				["@class.outer"] = "<c-v>",
			},
			include_surrounding_whitespace = false,
		},
		move = {
			set_jumps = true,
		},
	})

	local select = require("nvim-treesitter-textobjects.select")
	local move = require("nvim-treesitter-textobjects.move")
	local swap = require("nvim-treesitter-textobjects.swap")

	map({ "x", "o" }, "af", function()
		select.select_textobject("@function.outer", "textobjects")
	end, "around a function")
	map({ "x", "o" }, "if", function()
		select.select_textobject("@function.inner", "textobjects")
	end, "inner part of a function")
	map({ "x", "o" }, "ac", function()
		select.select_textobject("@class.outer", "textobjects")
	end, "around a class")
	map({ "x", "o" }, "ic", function()
		select.select_textobject("@class.inner", "textobjects")
	end, "inner part of a class")
	map({ "x", "o" }, "ai", function()
		select.select_textobject("@conditional.outer", "textobjects")
	end, "around an if statement")
	map({ "x", "o" }, "ii", function()
		select.select_textobject("@conditional.inner", "textobjects")
	end, "inner part of an if statement")
	map({ "x", "o" }, "al", function()
		select.select_textobject("@loop.outer", "textobjects")
	end, "around a loop")
	map({ "x", "o" }, "il", function()
		select.select_textobject("@loop.inner", "textobjects")
	end, "inner part of a loop")
	map({ "x", "o" }, "ap", function()
		select.select_textobject("@parameter.outer", "textobjects")
	end, "around parameter")
	map({ "x", "o" }, "ip", function()
		select.select_textobject("@parameter.inner", "textobjects")
	end, "inside a parameter")

	map({ "n", "x", "o" }, "[f", function()
		move.goto_previous_start("@function.outer", "textobjects")
	end, "Previous function")
	map({ "n", "x", "o" }, "[c", function()
		move.goto_previous_start("@class.outer", "textobjects")
	end, "Previous class")
	map({ "n", "x", "o" }, "[p", function()
		move.goto_previous_start("@parameter.inner", "textobjects")
	end, "Previous parameter")
	map({ "n", "x", "o" }, "]f", function()
		move.goto_next_start("@function.outer", "textobjects")
	end, "Next function")
	map({ "n", "x", "o" }, "]c", function()
		move.goto_next_start("@class.outer", "textobjects")
	end, "Next class")
	map({ "n", "x", "o" }, "]p", function()
		move.goto_next_start("@parameter.inner", "textobjects")
	end, "Next parameter")

	map("n", "<leader>a", function()
		swap.swap_next("@parameter.inner")
	end, "Swap next parameter")
	map("n", "<leader>A", function()
		swap.swap_previous("@parameter.inner")
	end, "Swap previous parameter")
end

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false,
	build = ":TSUpdate",
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter-textobjects",
			branch = "main",
		},
	},
	config = function()
		require("nvim-treesitter").setup({})
		vim.schedule(ensure_parsers_installed)
		setup_textobjects()

		local group = vim.api.nvim_create_augroup("user-treesitter", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			group = group,
			callback = function(args)
				local bufnr = args.buf
				local ok = pcall(vim.treesitter.start, bufnr)
				if not ok then
					return
				end

				local filetype = vim.bo[bufnr].filetype
				local lang = vim.treesitter.language.get_lang(filetype) or filetype
				if has_indent_query(lang) then
					vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
