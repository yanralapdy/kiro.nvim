local M = {}

function M.find_pane()
  local r = vim.system({ "tmux", "list-panes", "-a", "-F", "#{pane_id} #{pane_current_command}" }, { text = true }):wait()
  if r.code ~= 0 then return nil end
  for line in r.stdout:gmatch("[^\n]+") do
    local pane_id, cmd = line:match("^(%S+)%s+(.+)$")
    if pane_id and cmd:find("kiro") then return pane_id end
  end
end

function M.send_keys(pane, text)
  vim.system({ "tmux", "send-keys", "-t", pane, "\x1b[200~" }):wait()
  vim.system({ "tmux", "send-keys", "-t", pane, text }):wait()
  vim.system({ "tmux", "send-keys", "-t", pane, "\x1b[201~" }):wait()
  vim.system({ "tmux", "send-keys", "-t", pane, "Enter" }):wait()
end

return M
