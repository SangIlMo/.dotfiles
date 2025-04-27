local wezterm = require 'wezterm'

local module = {}

function module.apply_to_config(config)
  config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 1000 }

  config.keys = {
    -- 창 분할
    { key = "%", mods = "LEADER", action = wezterm.action.SplitHorizontal{domain = "CurrentPaneDomain"} },
    { key = '"', mods = "LEADER", action = wezterm.action.SplitVertical{domain = "CurrentPaneDomain"} },

    -- 패널 이동
    { key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
    { key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
    { key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
    { key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },

    -- 패널 닫기
    { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane{confirm = true} },

    -- 패널 크기 조정 (Alt + 방향키 느낌)
    { key = "h", mods = "ALT", action = wezterm.action.AdjustPaneSize{"Left", 5} },
    { key = "l", mods = "ALT", action = wezterm.action.AdjustPaneSize{"Right", 5} },
    { key = "k", mods = "ALT", action = wezterm.action.AdjustPaneSize{"Up", 5} },
    { key = "j", mods = "ALT", action = wezterm.action.AdjustPaneSize{"Down", 5} },

    -- 새 탭 열기
    { key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },

    -- 탭 이동 (n: next, p: previous)
    { key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
    { key = "p", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },
  }
end

return module
