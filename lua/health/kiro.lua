local M = {}

function M.check()
  vim.health.start("kiro.nvim")

  -- Check tmux
  local tmux = vim.system({ "tmux", "-V" }, { text = true }):wait()
  if tmux.code == 0 then
    vim.health.ok("tmux: " .. tmux.stdout:gsub("\n", ""))
  else
    vim.health.error("tmux not found — kiro.nvim requires tmux to communicate with kiro-cli")
  end

  -- Check kiro-cli pane
  local found, pane = pcall(function()
    return require("kiro.tmux").find_pane()
  end)
  if found and pane then
    vim.health.ok("kiro-cli pane found: " .. pane)
  elseif found then
    vim.health.warn("No kiro-cli pane found — start kiro-cli in a tmux pane first")
  else
    vim.health.error("Failed to check for kiro pane: " .. (pane or "unknown error"))
  end

  -- Check snacks.nvim
  local ok, _ = pcall(require, "snacks")
  if ok then
    vim.health.ok("snacks.nvim loaded")
  else
    vim.health.warn("snacks.nvim not found — ask_selection and select will not work")
  end

  -- Check plugin module loads
  local loaded, kiro = pcall(require, "kiro")
  if loaded then
    vim.health.ok("kiro.nvim loaded: setup() available = " .. tostring(type(kiro.setup)))
  else
    vim.health.error("kiro.nvim failed to load: " .. kiro)
  end
end

return M
