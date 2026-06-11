local M = {}

function M.send_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local path = vim.fn.expand("%")
  local ft = vim.bo.filetype
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  local text = string.format("%s:%d-%d\n```%s\n%s\n```", path, row, row, ft, line)
  require("kiro").send_prompt(text)
end

function M.send_range(srow, erow)
  srow = srow or vim.api.nvim_win_get_cursor(0)[1]
  erow = erow or srow
  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  local code = table.concat(lines, "\n")
  local path = vim.fn.expand("%")
  local ft = vim.bo.filetype
  local text = string.format("%s:%d-%d\n```%s\n%s\n```", path, srow, erow, ft, code)
  require("kiro").send_prompt(text)
end

function M.opfunc()
  -- Capture any visual selection before it gets cleared
  local visual = require("kiro.visual")
  visual.capture()

  -- Get range from visual module
  local srow, erow = visual.get_range()

  M.send_range(srow, erow)
end

function M.operator()
  vim.o.opfunc = "v:lua.require'kiro.operator'.opfunc"
  return "g@"
end

return M