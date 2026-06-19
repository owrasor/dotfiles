local blink = require("blink.cmp")

local get_intelephense_license = function()
	local env_key = vim.env.INTELEPHENSE_LICENSE_KEY
	if env_key and env_key ~= "" then
		return (env_key:gsub("%s+", ""))
	end

	local license_path = vim.fn.expand("~/intelephense/license.txt")
	local f = io.open(license_path, "rb")
	if not f then
		return nil
	end

	local content = f:read("*a")
	f:close()
	content = content:gsub("%s+", "")

	if content == "" then
		return nil
	end

	return content
end

return {
	cmd = { "intelephense", "--stdio" },
	filetypes = { "php", "blade" },
	root_markers = { "composer.json", ".git" },
	init_options = {
		licenceKey = get_intelephense_license(),
	},
	settings = {
		intelephense = {
			completion = {
				insertUseDeclaration = true,
			},
			files = {
				maxSize = 50000000,
			},
			environment = {
				shortOpenTag = true,
			},
		},
	},
	capabilities = vim.tbl_deep_extend(
		"force",
		{},
		vim.lsp.protocol.make_client_capabilities(),
		blink.get_lsp_capabilities()
	),
}
