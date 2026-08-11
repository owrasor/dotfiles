local blink = require("blink.cmp")

local home = vim.fn.expand("~")
local perl5lib = home .. "/perl5/lib/perl5"
local perlnavigator = vim.fn.exepath("perlnavigator")

if perlnavigator == "" then
	perlnavigator = "perlnavigator"
end

return {
	cmd = { perlnavigator },
	filetypes = { "perl" },
	root_markers = { "cpanfile", "Makefile.PL", "dist.ini", ".git" },
	settings = {
		perlnavigator = {
			perlPath = "perl",
			includeLib = true,
			includePaths = {
				"$workspaceFolder/lib",
				perl5lib,
			},
			perlEnv = {
				PERL5LIB = perl5lib,
				PERL_LOCAL_LIB_ROOT = home .. "/perl5",
				PERL_MB_OPT = "--install_base " .. home .. "/perl5",
				PERL_MM_OPT = "INSTALL_BASE=" .. home .. "/perl5",
				PATH = home .. "/perl5/bin:" .. vim.env.PATH,
			},
			perlEnvAdd = true,
			perlCompileEnabled = true,
			perlcriticEnabled = true,
			perlcriticSeverity = 4,
			perltidyEnabled = true,
		},
	},
	capabilities = vim.tbl_deep_extend(
		"force",
		{},
		vim.lsp.protocol.make_client_capabilities(),
		blink.get_lsp_capabilities()
	),
}
