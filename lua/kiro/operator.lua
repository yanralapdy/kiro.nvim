local M = {}

function M.send_line()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local path = vim.fn.expand("%")
  local ft = vim.bo.filetype
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  local text = require("kiro.context").format_block(path, row, row, ft, line)
  require("kiro").send_prompt(text)
end

function M.send_range(srow, erow)
  srow = srow or vim.api.nvim_win_get_cursor(0)[1]
  erow = erow or srow
  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  local code = table.concat(lines, "\n")
  local path = vim.fn.expand("%")
  local ft = vim.bo.filetype
  local text = require("kiro.context").format_block(path, srow, erow, ft, code)
  require("kiro").send_prompt(text)
end

function M.opfunc()
  -- g@ sets '[ and '] marks for the operator range, not '< and '>
  local srow = vim.fn.getpos("'[")[2]
  local erow = vim.fn.getpos("']")[2]

  if srow > 0 and erow > 0 then
    if srow > erow then
      srow, erow = erow, srow
    end
    M.send_range(srow, erow)
  else
    -- Fallback to visual module if operator marks aren't available
    local visual = require("kiro.visual")
    local vsrow, verow = visual.get_range()
    M.send_range(vsrow, verow)
  end
end

function M.operator()
  vim.o.opfunc = "v:lua.require'kiro.operator'.opfunc"
  return "g@"
end

return M