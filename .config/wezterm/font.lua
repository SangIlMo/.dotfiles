local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config)

   config.font = wezterm.font_with_fallback {
     { family = "JetBrainsMono Nerd Font", weight = "Regular", stretch = "Normal", style = "Normal" },
     { family = "Monaco", weight = "Regular", stretch = "Normal", style = "Normal" },
   }

   config.font_size = 13.0
end

return module
