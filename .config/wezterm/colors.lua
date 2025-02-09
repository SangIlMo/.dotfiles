local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config)

   config.color_scheme = 'Catppuccin Mocha'
   -- config.color_scheme = 'Dracula'
end

return module
