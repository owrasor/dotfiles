local wezterm = require("wezterm")
local config = wezterm.config_builder()
local mux = wezterm.mux

config.font_size = 12
config.line_height = 1.0
-- config.font = wezterm.font("MesloLGS NF Bold")
config.font = wezterm.font("FiraCode Nerd Font")
config.color_scheme = "tokyonight_night"

config.colors = {
    cursor_bg = "#7aa2f7",
    cursor_border = "7aa2f7",
}

config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.window_padding = {
    left = 10,
    right = 2,
    top = 2,
    bottom = 2,
}

wezterm.on('gui-startup', function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    window:gui_window():maximize()
end)

config.keys = {
    {
        key = "n",
        mods = "SHIFT|CTRL",
        action = wezterm.action.ToggleFullScreen,
    },
}

-- config.default_domain = "WSL:Ubuntu"
-- config.default_prog = { "wsl.exe", "-d", "Ubuntu" }

return config
