local M = {}

function M.format_block(path, srow, erow, filetype, code)
  return string.format(
    "TARGET_FILE: %s\nTARGET_LINES: %d-%d\n\nSELECTED_CODE:\n```%s\n%s\n```",
    path,
    srow,
    erow,
    filetype,
    code
  )
end

function M.build_file_prompt(path)
  return "TARGET_FILE: " .. path
end

function M.build_prompt(ctx, text)
  return ctx.formatted .. "\n\nUSER_REQUEST:\n" .. text
end

function M.get_this()
  local visual = require("kiro.visual")
  visual.capture()
  return visual.get_context().formatted
end

function M.get_buffer()
  local line_count = vim.api.nvim_buf_line_count(0)
  local code = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  return M.format_block(vim.fn.expand("%"), 1, line_count, vim.bo.filetype, code)
end

function M.get_visible()
  local win = vim.api.nvim_get_current_win()
  local top = vim.api.nvim_win_call(win, function()
    return vim.fn.line("w0")
  end)
  local bot = vim.api.nvim_win_call(win, function()
    return vim.fn.line("w$")
  end)
  local lines = vim.api.nvim_buf_get_lines(0, top - 1, bot, false)
  return M.format_block(vim.fn.expand("%"), top, bot, vim.bo.filetype, table.concat(lines, "\n"))
end

function M.get_diagnostics()
  local visual = require("kiro.visual")
  local srow, erow = visual.get_range()
  local diagnostics = vim.diagnostic.get(0)
  if #diagnostics == 0 then
    return ""
  end
  local seen = {}
  local lines = {}
  for _, d in ipairs(diagnostics) do
    local line = d.lnum + 1 -- 0-indexed to 1-indexed
    if line >= srow and line <= erow then
      local key = string.format("%d:%s", line, d.message)
      if not seen[key] then
        seen[key] = true
        table.insert(lines, string.format("Line %d: %s", line, d.message))
      end
    end
  end
  if #lines == 0 then
    return ""
  end
  return table.concat(lines, "\n")
end

function M.replace_placeholders(text)
  text = text:gsub("@this", M.get_this())
  text = text:gsub("@buffer", M.get_buffer())
  text = text:gsub("@visible", M.get_visible())
  text = text:gsub("@diagnostics", M.get_diagnostics())
  return text
end

return M