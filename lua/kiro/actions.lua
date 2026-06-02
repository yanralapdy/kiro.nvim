local M = {}

local function resolve_pane()
  local config = require("kiro").config
  local pane = config.pane or require("kiro.tmux").find_pane()
  if not pane then
    vim.notify("[kiro] no kiro pane found", vim.log.levels.ERROR)
  end
  return pane
end

function M.send_file()
  local pane = resolve_pane()
  if not pane then return end
  local path = vim.fn.expand("%")
  if path == "" then
    vim.notify("[kiro] no file in current buffer", vim.log.levels.ERROR)
    return
  end
  require("kiro.tmux").send_keys(pane, require("kiro").config.prefix .. path)
end

function M.ask_selection()
  local pane = resolve_pane()
  if not pane then return end

  local ok, snacks = pcall(require, "snacks")
  if not ok then
    vim.notify("[kiro] snacks.nvim is required for ask_selection", vim.log.levels.ERROR)
    return
  end

  local srow = vim.api.nvim_buf_get_mark(0, "<")[1]
  local erow = vim.api.nvim_buf_get_mark(0, ">")[1]
  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  local ft = vim.bo.filetype
  local path = vim.fn.expand("%")

  snacks.input({ prompt = "Ask kiro: " }, function(input)
    if not input or input == "" then return end
    local msg = string.format("%s:%d-%d\n```%s\n%s\n```\n%s", path, srow, erow, ft, table.concat(lines, "\n"), input)
    require("kiro.tmux").send_keys(pane, msg)
  end)
end

return M
