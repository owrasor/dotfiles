local wezterm = require("wezterm")

local my_rosepine = wezterm.color.get_builtin_schemes()["rose-pine"]
my_rosepine.background = "black"

local my_default = wezterm.color.get_default_colors()
my_default.background = "black"

return {
	color_schemes = {
		["my-rose-pine"] = my_rosepine,
		["my-default"] = my_default,
	},
	color_scheme = "my-rose-pine",
}
