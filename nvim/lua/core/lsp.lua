local function restart_lsp(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ bufnr = bufnr })

	for _, client in ipairs(clients) do
		vim.lsp.stop_client(client.id)
	end

	vim.defer_fn(function()
		vim.cmd("edit")
	end, 100)
end

vim.api.nvim_create_user_command("LspRestart", function()
	restart_lsp()
end, {})

vim.api.nvim_create_user_command("LspInfo", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = {
		"LSP clients attached to current buffer:",
		"filetype: " .. vim.bo[bufnr].filetype,
	}

	local clients = vim.lsp.get_clients({ bufnr = bufnr })
	if #clients == 0 then
		table.insert(lines, "none")
	else
		for _, client in ipairs(clients) do
			local root = client.config.root_dir or client.root_dir or "-"
			local code_action = client.server_capabilities.codeActionProvider and "yes" or "no"
			table.insert(lines, string.format("- %s | root: %s | code actions: %s", client.name, root, code_action))
		end
	end

	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LspInfo" })
end, {})

local function formatter_status()
	local ok, conform = pcall(require, "conform")
	if not ok then
		return ""
	end

	local formatters = conform.list_formatters_to_run(0)
	if #formatters == 0 then
		return ""
	end

	local formatter_names = {}
	for _, formatter in ipairs(formatters) do
		table.insert(formatter_names, formatter.name)
	end

	return "󰉿 " .. table.concat(formatter_names, ",")
end

local function linter_status()
	local ok, lint = pcall(require, "lint")
	if not ok then
		return ""
	end

	local linters = lint.linters_by_ft[vim.bo.filetype] or {}
	if #linters == 0 then
		return ""
	end

	return "󰁨 " .. table.concat(linters, ",")
end

local function safe_formatter_status()
	local ok, result = pcall(formatter_status)
	return ok and result or ""
end

local function safe_linter_status()
	local ok, result = pcall(linter_status)
	return ok and result or ""
end

--Criando variávei globais para uso no lualine
_G.formatter_status = safe_formatter_status
_G.linter_status = safe_linter_status
