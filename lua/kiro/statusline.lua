local M = {}

function M.statusline()
  local pane = require("kiro").config.pane or require("kiro.tmux").find_pane()
  return pane and "🟢 kiro" or "🔴 kiro"
end

return M
