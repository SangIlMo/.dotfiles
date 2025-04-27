local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config)
  wezterm.on("update-status", function(window, pane)
    local time = wezterm.strftime("%Y-%m-%d %H:%M:%S")
    window:set_right_status(time)
  end)
end

return module
