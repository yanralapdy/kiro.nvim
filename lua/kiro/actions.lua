local M = {}

local session = require("kiro.session")

function M.send_file()
  local path = vim.fn.expand("%")
  if path == "" then
    vim.notify("[kiro] no file in current buffer", vim.log.levels.ERROR)
    return
  end
  session.try_forward(require("kiro.context").build_file_prompt(path), false)
end

function M.ask_selection()
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    vim.notify("[kiro] snacks.nvim is required for ask_selection", vim.log.levels.ERROR)
    return
  end

  local ctx = require("kiro.visual").get_context()

  vim.notify(string.format("[kiro] Selection: %d-%d", ctx.srow, ctx.erow))

  snacks.input({ prompt = "Ask kiro: " }, function(input)
    if not input or input == "" then return end
    session.try_forward(require("kiro.context").build_prompt(ctx, input), false) -- always manual submit
  end)
end

function M.send_prompt(prompt)
  local text = require("kiro.context").replace_placeholders(prompt)
  session.try_forward(text, require("kiro").config.autosubmit)
end

function M.ask_with_prompt(prompt_name, context)
  local prompt = require("kiro.prompts").get_prompt(prompt_name)
  if not prompt then
    vim.notify("[kiro] Unknown prompt: " .. prompt_name, vim.log.levels.ERROR)
    return
  end

  local ctx = context or require("kiro.visual").get_context()
  local text = prompt.prompt:gsub("@this", "the selected code")
  text = require("kiro.context").replace_placeholders(text)

  session.try_forward(require("kiro.context").build_prompt(ctx, text), require("kiro").config.autosubmit)
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