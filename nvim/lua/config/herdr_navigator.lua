local M = {}

local directions = {
	h = "left",
	j = "down",
	k = "up",
	l = "right",
}

local function focus_herdr(direction)
	if vim.fn.executable("herdr") ~= 1 then
		return
	end

	vim.fn.jobstart({ "herdr", "pane", "focus", "--current", "--direction", direction }, { detach = true })
end

function M.navigate(wincmd, direction)
	local current_win = vim.api.nvim_get_current_win()
	vim.cmd("wincmd " .. wincmd)

	if current_win == vim.api.nvim_get_current_win() then
		focus_herdr(direction or directions[wincmd])
	end
end

function M.setup()
	local opts = { silent = true }
	local mappings = {
		{ key = "<C-h>", wincmd = "h", direction = "left", desc = "Navigate left" },
		{ key = "<C-j>", wincmd = "j", direction = "down", desc = "Navigate down" },
		{ key = "<C-k>", wincmd = "k", direction = "up", desc = "Navigate up" },
		{ key = "<C-l>", wincmd = "l", direction = "right", desc = "Navigate right" },
	}

	for _, mapping in ipairs(mappings) do
		vim.keymap.set("n", mapping.key, function()
			M.navigate(mapping.wincmd, mapping.direction)
		end, vim.tbl_extend("force", opts, { desc = mapping.desc }))

		vim.keymap.set("t", mapping.key, function()
			vim.cmd("stopinsert")
			M.navigate(mapping.wincmd, mapping.direction)
		end, vim.tbl_extend("force", opts, { desc = mapping.desc }))
	end

	vim.api.nvim_create_user_command("HerdrNavigateLeft", function()
		M.navigate("h", "left")
	end, {})
	vim.api.nvim_create_user_command("HerdrNavigateDown", function()
		M.navigate("j", "down")
	end, {})
	vim.api.nvim_create_user_command("HerdrNavigateUp", function()
		M.navigate("k", "up")
	end, {})
	vim.api.nvim_create_user_command("HerdrNavigateRight", function()
		M.navigate("l", "right")
	end, {})
	vim.api.nvim_create_user_command("HerdrNavigatePrevious", function()
		vim.cmd("wincmd p")
	end, {})
end

return M
