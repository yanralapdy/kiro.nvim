local M = {}

function M.get_context()
  local visual = require("kiro.visual")
  visual.capture()
  return visual.get_context()
end

function M.select()
  local visual = require("kiro.visual")
  visual.capture()

  local items = {
    { text = "Send File", action = function()
      require("kiro").send_file()
    end },
    { text = "Ask Selection", action = function()
      require("kiro").ask_selection()
    end },
    { text = "Select Prompt (with context)", action = function()
      require("kiro").select_and_ask()
    end },
  }

  local prompts = require("kiro.prompts").get_all()
  for name, prompt in pairs(prompts) do
    table.insert(items, {
      text = "Prompt: " .. prompt.name,
      action = function()
        require("kiro").ask_with_prompt(name)
      end,
    })
  end

  vim.ui.select(items, {
    prompt = "Select kiro action:",
    format_item = function(item)
      return item.text
    end,
  }, function(item)
    if item and item.action then
      item.action()
    end
  end)
end

return M