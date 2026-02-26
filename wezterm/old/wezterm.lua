local wezterm = require("wezterm")
local constants = require("constants")
local colorschemes = require("colorschemes")

local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.color_schemes = colorschemes.color_schemes
config.color_scheme = colorschemes.color_scheme

config.default_cursor_style = "SteadyBar"
config.automatically_reload_config = true
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.font_size = 16
config.prefer_egl = true
config.max_fps = 120
config.font = wezterm.font("JetBrains Mono", { weight = "Bold" })
config.enable_tab_bar = false
config.window_padding = {
	left = "0px",
	right = "0px",
	top = "0px",
	bottom = "0px",
}

config.window_background_image = constants.image_black
config.window_background_opacity = 1
config.macos_window_background_blur = 40

config.window_background_image_hsb = {
	-- Darken the background image by reducing it to 1/3rd
	brightness = 0.02,

	-- You can adjust the hue by scaling its value.
	-- a multiplier of 1.0 leaves the value unchanged.
	hue = 1.0,

	-- You can adjust the saturation also.
	saturation = 1.0,
}

config.foreground_text_hsb = {
	hue = 1.0,
	saturation = 1.0,
	brightness = 1.0,
}

return config -- Pull in the wezterm API
