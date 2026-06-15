local M = {}

M.config = {
  pane = nil,
  prefix = "look at ",
  features = {
    context = true,
    prompts = true,
    operator = true,
    commands = true,
    statusline = true,
    checkhealth = true,
    select = true,
  },
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Patch tmux bindings for vim-tmux-navigator compatibility
  pcall(function() require("kiro.vim-tmux-navigator").setup() end)

  -- Setup visual mode detection autocmds
  local visual = require("kiro.visual")
  visual.setup_autocmds()
end

local actions = require("kiro.actions")
M.send_file = actions.send_file
M.ask_selection = actions.ask_selection
M.send_prompt = actions.send_prompt
M.ask_with_prompt = actions.ask_with_prompt
M.select_and_ask = actions.select_and_ask

require("kiro.operator")
M.operator = require("kiro.operator").operator

local select = require("kiro.select")
M.select = select.select

local commands = require("kiro.commands")
M.command = commands.execute

local statusline = require("kiro.statusline")
M.statusline = statusline.statusline

local health = require("kiro.health")
M.check = health.check

-- Expose visual module for direct access if needed
M.visual = require("kiro.visual")

return M