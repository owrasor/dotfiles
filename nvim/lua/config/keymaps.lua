-- Move blocks up and down
vim.keymap.set("v", "<M-Down>", ":m '>+1<CR>gv=gv", { desc = "Move lines down in visual selection" })
vim.keymap.set("v", "<M-Up>", ":m '<-2<CR>gv=gv", { desc = "Move lines up in visual selection" })

-- Clear search highlighting.
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Maintain the cursor position when yanking a visual selection.
-- http://ddrscott.github.io/blog/2016/yank-without-jank/
vim.keymap.set("v", "y", "myy`y")
vim.keymap.set("v", "Y", "myY`y")

-- Paste replace visual selection without copying it.
vim.keymap.set("v", "p", '"_dP')
vim.keymap.set("v", "x", '"_x')

vim.keymap.set("n", "<leader>cn", ':let @* = expand("%:t")<cr>', { desc = "Copy filename of current file to registry" })
vim.keymap.set("n", "<leader>cp", ':let @* = expand("%")<cr>', { desc = "Copy path of current file to registry" })

-- TODO keymaps
vim.keymap.set("n", "]t", function()
	require("todo-comments").jump_next()
end, { desc = "Next todo comment" })

vim.keymap.set("n", "[t", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })

-- You can also specify a list of valid jump keywords

vim.keymap.set("n", "]t", function()
	require("todo-comments").jump_next({ keywords = { "ERROR", "WARNING" } })
end, { desc = "Next error/warning todo comment" })

vim.keymap.set("n", "<C-e>", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Database commands
vim.keymap.set("n", "<C-i>", "<CMD>DBUIToggle<CR>", { desc = "Open database" })

local function toggle_diffview()
	local view = require("diffview.lib").get_current_view()
	if view then
		vim.cmd("DiffviewClose")
	else
		vim.cmd("DiffviewOpen")
	end
end

-- Mapeie o atalho, por exemplo <leader>d
vim.keymap.set("n", "<leader>df", toggle_diffview, { desc = "Toggle Diffview" })

vim.keymap.set(
	"n",
	"<leader>fr",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Replace word under cursor" }
)

vim.keymap.set("n", "<leader>w", ":write<CR>", { desc = "Save file" })
