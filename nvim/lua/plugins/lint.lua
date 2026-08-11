return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local lint = require("lint")

		local perl5lib = vim.fn.expand("~/perl5/lib/perl5")

		lint.linters.perl_compile = {
			cmd = "perl",
			stdin = false,
			append_fname = true,
			args = { "-Ilib", "-I" .. perl5lib, "-c" },
			stream = "stderr",
			ignore_exitcode = true,
			parser = function(output, bufnr)
				local diagnostics = {}
				local filename = vim.api.nvim_buf_get_name(bufnr)

				for line in output:gmatch("[^\r\n]+") do
					if not line:match("syntax OK$") then
						local message, lnum = line:match("^(.-) at .- line (%d+)[%.,]?")
						if message and lnum then
							table.insert(diagnostics, {
								filename = filename,
								lnum = tonumber(lnum),
								col = 1,
								message = message,
								severity = vim.diagnostic.severity.ERROR,
								source = "perl -c",
							})
						end
					end
				end

				return diagnostics
			end,
			env = {
				PERL5LIB = perl5lib,
				PERL_LOCAL_LIB_ROOT = vim.fn.expand("~/perl5"),
				PERL_MB_OPT = "--install_base " .. vim.fn.expand("~/perl5"),
				PERL_MM_OPT = "INSTALL_BASE=" .. vim.fn.expand("~/perl5"),
			},
		}

		lint.linters_by_ft = {
			markdown = { "markdownlint" },
			perl = { "perl_compile" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
