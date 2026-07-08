local M = {}

-- Module-level storage for the last visual selection range
local _visual_range = nil

-- Setup ModeChanged autocmds
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup("KiroVisual", { clear = true })

  -- Capture marks when exiting visual mode to normal mode
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "[vVxX]:n",
    callback = function(args)
      local srow = vim.fn.getpos("'<")[2]
      local erow = vim.fn.getpos("'>")[2]
      if srow > 0 and erow > 0 then
        _visual_range = { srow = srow, erow = erow }
      end
    end,
  })

  -- Also capture when toggling between visual submodes
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "[vVxX]:[vVxX]",
    callback = function(args)
      local srow = vim.fn.getpos("'<")[2]
      local erow = vim.fn.getpos("'>")[2]
      if srow > 0 and erow > 0 then
        _visual_range = { srow = srow, erow = erow }
      end
    end,
  })

  -- Clear cache when entering visual mode (prevents stale cache)
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "n:[vVxX]",
    callback = function(args)
      _visual_range = nil
    end,
  })
end

-- Debug function to get all relevant info
function M.debug_info()
  local mode = vim.fn.mode()
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local srow = vim.fn.getpos("'<")[2]
  local erow = vim.fn.getpos("'>")[2]
  local v_srow = vim.fn.getpos("v")[2]
  local v_erow = vim.fn.getpos(".")[2]
  local cached = _visual_range
  return {
    mode = mode,
    cursor = cursor,
    srow = srow,
    erow = erow,
    v_srow = v_srow,
    v_erow = v_erow,
    cached = cached,
    mode_match = mode:match("[vVxX]") ~= nil,
  }
end

-- Get the current visual selection range
-- Priority: 1. Cached range (from ModeChanged autocmd)
--          2. Current marks (if in visual mode and marks are valid)
--          3. Cursor position (single line)
function M.get_range()
  local mode = vim.fn.mode()
  
  -- Debug: write entry to debug file
  local srow_direct = vim.fn.getpos("'<")[2]
  local erow_direct = vim.fn.getpos("'>")[2]
  local f = io.open("/tmp/kiro-debug.txt", "a")
  if f then
    f:write(string.format("[get_range] ENTER mode=%s marks=<%d,%d> cache=%s\n", 
      mode, srow_direct, erow_direct, 
      _visual_range and (_visual_range.srow .. "-" .. _visual_range.erow) or "nil"))
    f:close()
  end
  
  -- Priority 1: If in visual mode, use getpos("v") and getpos(".") for current selection
  -- (getpos("'<") is only set after exiting visual mode)
  if mode:match("[vVxX]") then
    local srow = vim.fn.getpos("v")[2]
    local erow = vim.fn.getpos(".")[2]
    if srow > 0 and erow > 0 then
      if f then
        f = io.open("/tmp/kiro-debug.txt", "a")
        f:write(string.format("[get_range] USING VISUAL_POS srow=%d erow=%d\n", srow, erow))
        f:close()
      end
      if srow > erow then
        srow, erow = erow, srow
      end
      _visual_range = { srow = srow, erow = erow }
      return srow, erow
    else
      if f then
        f = io.open("/tmp/kiro-debug.txt", "a")
        f:write("[get_range] VISUAL_POS INVALID (0,0), falling back to cursor\n")
        f:close()
      end
    end
  end
  
  -- Priority 2: Check marks (getpos("'<")/getpos("'>") - set after exiting visual mode)
  local srow = vim.fn.getpos("'<")[2]
  local erow = vim.fn.getpos("'>")[2]
  if srow > 0 and erow > 0 then
    if f then
      f = io.open("/tmp/kiro-debug.txt", "a")
      f:write(string.format("[get_range] USING MARKS srow=%d erow=%d\n", srow, erow))
      f:close()
    end
    if srow > erow then
      srow, erow = erow, srow
    end
    _visual_range = { srow = srow, erow = erow }
    return srow, erow
  end
  
  -- Priority 3: Check cached range
  if _visual_range then
    if f then
      f = io.open("/tmp/kiro-debug.txt", "a")
      f:write(string.format("[get_range] USING CACHE %d-%d\n", _visual_range.srow, _visual_range.erow))
      f:close()
    end
    return _visual_range.srow, _visual_range.erow
  end
  
  -- Priority 4: Fall back to cursor
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  if f then
    f = io.open("/tmp/kiro-debug.txt", "a")
    f:write(string.format("[get_range] USING CURSOR=%d\n", cursor))
    f:close()
  end
  return cursor, cursor
end

-- Get context from current selection
function M.get_context()
  local path = vim.fn.expand("%")
  local srow, erow = M.get_range()
  local ft = vim.bo.filetype

  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  local code = table.concat(lines, "\n")

  return {
    path = path,
    srow = srow,
    erow = erow,
    code = code,
    filetype = ft,
    formatted = require("kiro.context").format_block(path, srow, erow, ft, code),
  }
end

function M.clear()
  _visual_range = nil
end

-- Capture current visual selection
-- Returns true if a valid selection was captured, false otherwise
function M.capture()
  local mode = vim.fn.mode()
  
  -- If in visual mode, get selection start and cursor position
  if mode:match("[vVxX]") then
    local srow = vim.fn.getpos("v")[2]
    local erow = vim.fn.getpos(".")[2]
    if srow > 0 and erow > 0 then
      if srow > erow then
        srow, erow = erow, srow
      end
      _visual_range = { srow = srow, erow = erow }
      return true
    end
  end
  
  -- Fall back to existing cached range
  if _visual_range then
    return true
  end
  
  return false
end

return M