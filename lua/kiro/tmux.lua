local M = {}

function M.find_pane()
  local r = vim.system({ "tmux", "list-panes", "-a", "-F", "#{pane_id} #{pane_pid}" }, { text = true }):wait()
  if r.code ~= 0 then return nil end

  -- get full process tree once
  local ps = vim.system({ "ps", "-A", "-o", "pid=,ppid=,command=" }, { text = true }):wait()
  if not ps.stdout then return nil end

  -- build parent->children map and pid->comm map
  local children = {}
  local comm = {}
  for line in ps.stdout:gmatch("[^\n]+") do
    local pid, ppid, cmd = line:match("^%s*(%d+)%s+(%d+)%s+(.+)$")
    if pid then
      comm[pid] = cmd
      children[ppid] = children[ppid] or {}
      table.insert(children[ppid], pid)
    end
  end

  local function has_kiro(pid)
    if comm[pid] and comm[pid]:match("^kiro%-cli") then return true end
    for _, cpid in ipairs(children[pid] or {}) do
      if has_kiro(cpid) then return true end
    end
    return false
  end

  for line in r.stdout:gmatch("[^\n]+") do
    local pane_id, pid = line:match("^(%S+)%s+(%S+)$")
    if pane_id and pid and has_kiro(pid) then return pane_id end
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
