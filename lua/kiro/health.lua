local M = {}

function M.check()
  vim.health.start("kiro.nvim")

  local tmux = vim.system({ "tmux", "-V" }, { text = true }):wait()
  if tmux.code == 0 then
    vim.health.ok("tmux: " .. tmux.stdout:gsub("\n", ""))
  else
    vim.health.error("tmux not found")
  end

  local pane = require("kiro.tmux").find_pane()
  if pane then
    vim.health.ok("kiro-cli pane found: " .. pane)
  else
    vim.health.warn("kiro-cli pane not found")
  end

  local ok, _ = pcall(require, "snacks")
  if ok then
    vim.health.ok("snacks.nvim loaded")
  else
    vim.health.warn("snacks.nvim not found (optional)")
  end
end

return M
