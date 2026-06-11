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

  local visual = require("kiro.visual")
  
  -- Get the range (this checks cache first, then marks, then cursor)
  local srow, erow = visual.get_range()
  
  -- Get debug info
  local debug = visual.debug_info()
  
  -- Write debug output
  local debug_msg = string.format("[kiro DEBUG] mode=%s cursor=%d marks=<%d,%d> vpos=<%d,%d> cache=%s range=%d-%d", 
    debug.mode, debug.cursor, debug.srow, debug.erow, 
    debug.v_srow, debug.v_erow,
    debug.cached and (debug.cached.srow .. "-" .. debug.cached.erow) or "nil", 
    srow, erow)
  vim.api.nvim_out_write(debug_msg .. "\n")
  
  local f = io.open("/tmp/kiro-debug.txt", "a")
  if f then
    f:write(debug_msg .. "\n")
    f:close()
  end

  local path = vim.fn.expand("%")
  local ft = vim.bo.filetype

  vim.notify(string.format("[kiro] Selection: %d-%d", srow, erow))

  snacks.input({ prompt = "Ask kiro: " }, function(input)
    if not input or input == "" then return end
    local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
    local code = table.concat(lines, "\n")
    local msg = string.format("%s:%d-%d\n```%s\n%s\n```\n%s", path, srow, erow, ft, code, input)
    require("kiro.tmux").send_keys(pane, msg)
  end)
end

function M.send_prompt(prompt)
  local pane = resolve_pane()
  if not pane then return end
  local text = require("kiro.context").replace_placeholders(prompt)
  require("kiro.tmux").send_keys(pane, text)
end

function M.ask_with_prompt(prompt_name, context)
  local prompt = require("kiro.prompts").get_prompt(prompt_name)
  if not prompt then
    vim.notify("[kiro] Unknown prompt: " .. prompt_name, vim.log.levels.ERROR)
    return
  end

  local text = prompt.prompt
  local ctx = context or require("kiro.visual").get_context()

  text = text:gsub("@this", ctx.formatted)

  M.send_prompt(text)
end

function M.select_and_ask()
  local prompts = require("kiro.prompts").get_all()
  local items = {}
  for name, prompt in pairs(prompts) do
    table.insert(items, { text = prompt.name .. " - " .. prompt.description, name = name })
  end

  local visual = require("kiro.visual")
  local context = visual.get_context()

  vim.ui.select(items, {
    prompt = "Select kiro prompt:",
    format_item = function(item)
      return item.text
    end,
  }, function(item)
    if item and item.name then
      M.ask_with_prompt(item.name, context)
    end
  end)
end

return M