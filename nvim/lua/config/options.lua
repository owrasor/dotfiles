-- disable netrw at the very start of your init.lua for nvim-tree plugin
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.editorconfig = true

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- TABS e Identações
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

opt.wrap = false

-- search settings
opt.ignorecase = true
opt.smartcase = true

opt.cursorline = true

-- turn on termguicolors for tokyonight colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"
opt.scrolloff = 8

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard (Force Netcat if RNVIM_PORT exists, else fallback to OSC 52)
local rnvim_port = os.getenv("RNVIM_PORT")
if rnvim_port then
    local clip_port = "1" .. rnvim_port
    vim.g.clipboard = {
        name = 'Remote/RNVIM',
        copy = {
            ['+'] = {'bash', '-c', 'cat > /dev/tcp/127.0.0.1/' .. clip_port},
            ['*'] = {'bash', '-c', 'cat > /dev/tcp/127.0.0.1/' .. clip_port},
        },
        paste = {
            ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
            ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
    }
else
    vim.g.clipboard = {
        name = 'OSC 52',
        copy = {
            ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
            ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
            ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
            ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
        },
    }
end
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false
-- Garante renderização perfeita em terminais modernos como Ghostty
opt.ttyfast = true
