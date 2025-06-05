-- Clear search highlighting.
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Maintain the cursor position when yanking a visual selection.
-- http://ddrscott.github.io/blog/2016/yank-without-jank/
vim.keymap.set("v", "y", "myy`y")
vim.keymap.set("v", "Y", "myY`y")

-- Paste replace visual selection without copying it.
vim.keymap.set("v", "p", '"_dP')

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
