local M = {}

M.config = { pane = nil, prefix = "look at " }

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local actions = require("kiro.actions")
M.send_file = actions.send_file
M.ask_selection = actions.ask_selection

return M
