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

local is_herdr = vim.env.HERDR_ENV ~= nil
local has_wayland_clipboard = vim.env.WAYLAND_DISPLAY ~= nil
    and vim.fn.executable("wl-copy") == 1
    and vim.fn.executable("wl-paste") == 1

if is_herdr and not has_wayland_clipboard then
    opt.clipboard = ""
    local herdr_clipboard = { ["+"] = { {}, "v" }, ["*"] = { {}, "v" } }
    vim.g.clipboard = {
        name = "Herdr local clipboard",
        copy = {
            ["+"] = function(lines, regtype)
                herdr_clipboard["+"] = { lines, regtype }
            end,
            ["*"] = function(lines, regtype)
                herdr_clipboard["*"] = { lines, regtype }
            end,
        },
        paste = {
            ["+"] = function()
                return herdr_clipboard["+"]
            end,
            ["*"] = function()
                return herdr_clipboard["*"]
            end,
        },
    }
elseif has_wayland_clipboard then
    vim.g.clipboard = {
        name = "wl-clipboard",
        copy = {
            ["+"] = "wl-copy --type text/plain",
            ["*"] = "wl-copy --primary --type text/plain",
        },
        paste = {
            ["+"] = "wl-paste --no-newline",
            ["*"] = "wl-paste --no-newline --primary",
        },
        cache_enabled = 0,
    }
    opt.clipboard:append("unnamedplus") -- use system clipboard as default register
else
    -- clipboard: OSC 52 (Neovim 0.10+). Em versões antigas o módulo não existe.
    local ok_osc52, osc52 = pcall(require, "vim.ui.clipboard.osc52")
    if ok_osc52 then
        vim.g.clipboard = {
            name = "OSC 52",
            copy = {
                ["+"] = osc52.copy("+"),
                ["*"] = osc52.copy("*"),
            },
            paste = {
                ["+"] = osc52.paste("+"),
                ["*"] = osc52.paste("*"),
            },
        }
    end
    opt.clipboard:append("unnamedplus") -- use system clipboard as default register
end

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
opt.swapfile = false
-- Garante renderização perfeita em terminais modernos como Ghostty
opt.ttyfast = true
