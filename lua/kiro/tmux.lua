local M = {}

function M.find_pane()
  local r = vim.system({ "tmux", "list-panes", "-a", "-F", "#{pane_id} #{pane_pid}" }, { text = true }):wait()
  if r.code ~= 0 then return nil end
  for line in r.stdout:gmatch("[^\n]+") do
    local pane_id, pid = line:match("^(%S+)%s+(%S+)$")
    if pane_id and pid then
      local c = vim.system({ "sh", "-c", "ps -o comm= $(pgrep -P " .. pid .. " 2>/dev/null) 2>/dev/null" }, { text = true }):wait()
      if c.stdout and c.stdout:find("kiro") then return pane_id end
    end
  end
end

function M.send_keys(pane, text)
  -- write text to a temp file, load into tmux buffer, paste to target pane, then send Enter
  local tmp = os.tmpname()
  local f = io.open(tmp, "w")
  f:write(text)
  f:close()
  vim.system({ "tmux", "load-buffer", "-b", "kiro_buf", tmp }):wait()
  os.remove(tmp)
  vim.system({ "tmux", "paste-buffer", "-b", "kiro_buf", "-t", pane }):wait()
  vim.system({ "tmux", "send-keys", "-t", pane, "Enter" }):wait()
end

return M
