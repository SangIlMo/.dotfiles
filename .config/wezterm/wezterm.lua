local colors = require("colors")
-- local panels = require 'panels'
local font = require("font")
local status = require("status")

local config = {}

colors.apply_to_config(config)
-- panels.apply_to_config(config)
font.apply_to_config(config)
status.apply_to_config(config)

config.scrollback_lines = 10000

return config
