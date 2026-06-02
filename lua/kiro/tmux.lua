local M = {}

function M.find_pane()
  local r = vim.system({ "tmux", "list-panes", "-a", "-F", "#{pane_id} #{pane_pid}" }, { text = true }):wait()
  if r.code ~= 0 then return nil end

  local ps = vim.system({ "ps", "-A", "-o", "pid=,ppid=,command=" }, { text = true }):wait()
  if not ps.stdout then return nil end

  local ch, comm = {}, {}
  for line in ps.stdout:gmatch("[^\n]+") do
    local pid, ppid, cmd = line:match("^%s*(%d+)%s+(%d+)%s+(.+)$")
    if pid then comm[pid] = cmd; ch[ppid] = ch[ppid] or {}; table.insert(ch[ppid], pid) end
  end

  local function has_kiro(pid)
    if comm[pid] and comm[pid]:match("^kiro%-cli") then return true end
    for _, c in ipairs(ch[pid] or {}) do if has_kiro(c) then return true end end
    return false
  end

  for line in r.stdout:gmatch("[^\n]+") do
    local pane_id, pid = line:match("^(%S+)%s+(%S+)$")
    if pane_id and pid and has_kiro(pid) then return pane_id end
  end
end

function M.send_keys(pane, text)
  local lines = vim.split(text, "\n", { plain = true })
  for i, line in ipairs(lines) do
    vim.system({ "tmux", "send-keys", "-t", pane, line, "" }):wait()
    if i < #lines then
      vim.system({ "tmux", "send-keys", "-t", pane, "M-Enter", "" }):wait()
    end
  end
  vim.system({ "tmux", "send-keys", "-t", pane, "", "Enter" }):wait()
end

return M
