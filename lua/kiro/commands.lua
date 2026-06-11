local M = {}

M.commands = {
  ["session.new"] = "/new",
  ["session.select"] = "/sessions",
  ["session.list"] = "/sessions",
  ["session.interrupt"] = "\x03",
  ["session.compact"] = "/compact",
  ["session.page.up"] = "\x1b[5~",
  ["session.page.down"] = "\x1b[6~",
  ["session.half.page.up"] = "\x1b[5~\x1b[5~",
  ["session.half.page.down"] = "\x1b[6~\x1b[6~",
  ["prompt.submit"] = "\r",
  ["prompt.clear"] = "\x15",
}

function M.execute(command)
  if not M.commands[command] then
    vim.notify("[kiro] Unknown command: " .. command, vim.log.levels.ERROR)
    return
  end
  local pane = require("kiro").config.pane or require("kiro.tmux").find_pane()
  if not pane then
    vim.notify("[kiro] No kiro pane found", vim.log.levels.ERROR)
    return
  end
  require("kiro.tmux").send_keys(pane, M.commands[command])
end

return M
