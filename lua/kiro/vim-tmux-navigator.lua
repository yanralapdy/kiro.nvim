--- Auto-patch tmux bindings so vim-tmux-navigator works with kiro-cli-term.
---
--- kiro-cli-term wraps nvim in a separate pty, so tmux's default is_vim
--- check (`ps -t #{pane_tty}`) cannot see nvim.  Instead of setting a pane
--- marker (which can go stale), we write a small shell script that walks the
--- process tree to find nvim descendants of the pane's process, and wire the
--- tmux C-h/j/k/l bindings to call it.

local M = {}

--- Check if a tmux option exists (returns value or nil).
local function tmux_get(option)
  local result = vim.fn.system({ "tmux", "show", "-g", "-v", option })
  if vim.v.shell_error == 0 and #result > 0 then
    return vim.trim(result)
  end
  return nil
end

--- Check if vi-style C-h/j/k/l bindings with the vim-tmux-navigator
--- if-shell pattern are present in the root key table.
local function has_vtn_bindings()
  local out = vim.fn.system("tmux list-keys -T root 2>/dev/null")
  return out:match("send%-keys%s+'?C%-[hjkl]'?.-select%-pane") ~= nil
end

--- Write the helper script that tmux will call on every C-h/j/k/l press.
local function write_script()
  local dir = vim.fn.stdpath("data") .. "/kiro-nvim"
  vim.fn.mkdir(dir, "p")
  local script_path = dir .. "/is_vim.sh"

  local content = [=[
#!/usr/bin/env bash
# Check if a tmux pane has vim/nvim, even when wrapped by kiro-cli-term.
# Called by tmux as: is_vim.sh '#{pane_tty}' '#{pane_pid}'
set -e

pane_tty="$1"
pane_pid="$2"

# 1. Fast path: nvim foreground on the pane's controlling terminal
#    (standard vim-tmux-navigator check)
if ps -o state= -o comm= -t "$pane_tty" 2>/dev/null \
  | grep -iqE '^[^TXZ ]+ +(\S+/)?g?\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?$'; then
  exit 0
fi

# 2. Walk up the parent chain from each nvim process, looking for pane_pid.
#    Handles kiro-cli-term where nvim is a descendant of the pane's shell.
if [ -n "$pane_pid" ]; then
  nvim_pids=$(pgrep -x nvim 2>/dev/null || true)
  for npid in $nvim_pids; do
    ppid=$npid
    depth=0
    while [ -n "$ppid" ] && [ "$ppid" != "1" ] && [ $depth -lt 10 ]; do
      ppid=$(ps -o ppid= -p "$ppid" 2>/dev/null | tr -d ' ')
      [ -z "$ppid" ] && break
      [ "$ppid" = "$pane_pid" ] && exit 0
      depth=$((depth + 1))
    done
  done
fi

exit 1
]=]

  local f = io.open(script_path, "w")
  if not f then return nil end
  f:write(content)
  f:close()
  os.execute("chmod +x " .. script_path)
  return script_path
end

--- Patch the tmux C-h/j/k/l root bindings to use the helper script.
local function patch_bindings(script_path)
  local is_vim = script_path .. " '#{pane_tty}' '#{pane_pid}'"

  local disable_zoomed = tmux_get("@tmux_navigator_disable_when_zoomed")
  local wrap_zoomed = (disable_zoomed == "1")

  local mappings = {
    { key = "C-h", forward = "send-keys C-h", fallback = "select-pane -L" },
    { key = "C-j", forward = "send-keys C-j", fallback = "select-pane -D" },
    { key = "C-k", forward = "send-keys C-k", fallback = "select-pane -U" },
    { key = "C-l", forward = "send-keys C-l", fallback = "select-pane -R" },
    { key = [[C-\]], forward = [[send-keys C-\]], fallback = "select-pane -l" },
  }

  for _, m in ipairs(mappings) do
    local fallback = m.fallback
    if wrap_zoomed then
      fallback = "if-shell -F '#{window_zoomed_flag}' '' '" .. fallback .. "'"
    end
    vim.fn.system({
      "tmux", "bind-key", "-n", m.key,
      "if-shell", is_vim,
      m.forward,
      fallback,
    })
  end
end

function M.setup()
  if not vim.env.TMUX then
    return
  end

  -- ── Write the helper script & patch tmux bindings (once per server) ──
  if tmux_get("@kiro_navigator_fix") ~= nil then
    return -- already done
  end

  if not has_vtn_bindings() then
    return -- vim-tmux-navigator not active
  end

  local script_path = write_script()
  if not script_path then
    return
  end

  vim.fn.system({ "tmux", "set", "-g", "@kiro_navigator_fix", "1" })
  patch_bindings(script_path)
end

return M
