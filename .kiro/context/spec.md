# kiro.nvim — Spec

## 1. Problem statement

Provide a Neovim plugin that sends editor context (current file, or a visual
selection plus a typed instruction) into an already-running `kiro-cli` session
living in a tmux pane, via `tmux send-keys`, without leaving the editor.

## 2. Detected stack & conventions

- Pure Lua Neovim plugin. No build tools, no package manifest, no dependencies
  to install (confirmed: directory contains only `.kiro/context/`).
- Runtime: Neovim 0.9+ (uses `vim.system`).
- Optional runtime dep: `snacks.nvim` (for `Snacks.input`), loaded defensively.
- Conventions: standard `*.nvim` layout — `plugin/` for the auto-loaded guard,
  `lua/<name>/` for modules, public surface via `require("kiro")`.
- Plugin sets NO keymaps; the user wires their own.

## 3. Files to create

```
/Users/tnkapdy/sites/lua/kiro.nvim/
├── plugin/kiro.lua          # auto-load guard only
├── lua/kiro/init.lua        # setup(opts), config table, re-exports
├── lua/kiro/tmux.lua        # find_pane(), send_keys(pane, text)
└── lua/kiro/actions.lua     # send_file(), ask_selection()
```

(README.md / .gitignore / git init are downstream steps, out of scope for this
spec.)

### plugin/kiro.lua
- Guard against double-load:
  ```lua
  if vim.g.loaded_kiro then return end
  vim.g.loaded_kiro = true
  ```
- Does nothing else. No keymaps, no `setup()` call, no commands required.

### lua/kiro/init.lua
- Holds `M.config` defaulting to `{ pane = nil, prefix = "look at " }`.
- `M.setup(opts)` — `vim.tbl_deep_extend("force", M.config, opts or {})`,
  storing the result back into `M.config`.
- Re-exports actions so users call `require("kiro").send_file()` and
  `require("kiro").ask_selection()` directly (delegate to `actions`).
- `actions` and `tmux` read config from this module (single source of truth).

### lua/kiro/tmux.lua
- `M.find_pane()`:
  - Runs `tmux list-panes -a -F "#{pane_id} #{pane_current_command}"` via
    `vim.system(..., { text = true }):wait()`.
  - On non-zero exit, return `nil`.
  - Parse stdout line by line; return the first `pane_id` whose
    `pane_current_command` contains `kiro` (substring match, case-sensitive ok).
  - Return `nil` if no match.
- `M.send_keys(pane, text)`:
  - Bracketed paste, as SEPARATE `tmux send-keys` invocations against `-t pane`:
    1. `tmux send-keys -t <pane> "\x1b[200~"`   (paste start)
    2. `tmux send-keys -t <pane> "<text>"`      (the payload, literal)
    3. `tmux send-keys -t <pane> "\x1b[201~"`   (paste end)
    4. `tmux send-keys -t <pane> "Enter"`       (submit)
  - The escape sequences must be passed as literal strings, never combined into
    one argument (per handoff gotcha).
  - Each call via `vim.system(...):wait()`.

### lua/kiro/actions.lua
- Resolves the target pane: use `config.pane` if set, else `tmux.find_pane()`.
  If no pane resolves, `vim.notify` an error and abort.
- `M.send_file()`:
  - Relative path of current buffer:
    `vim.fn.expand("%")` (relative to cwd; empty-buffer guard → notify + abort).
  - Calls `tmux.send_keys(pane, config.prefix .. path)`.
- `M.ask_selection()`:
  - Read visual marks (called from normal mode after visual exit, so `'<`/`'>`
    are set):
    `vim.api.nvim_buf_get_mark(0, "<")` → `{srow, _}`,
    `vim.api.nvim_buf_get_mark(0, ">")` → `{erow, _}` (rows are 1-indexed here).
  - Lines: `vim.api.nvim_buf_get_lines(0, srow-1, erow, false)`.
  - Filetype: `vim.bo.filetype` (used as the code-fence language `ft`).
  - Filepath: `vim.fn.expand("%")` (relative).
  - Guard `snacks`: `local ok, snacks = pcall(require, "snacks")`; if not ok,
    `vim.notify` that snacks.nvim is required and abort.
  - Open `Snacks.input({ prompt = ... })`, single-line. On cancel
    (nil/empty input) abort silently. On confirm, build the message and call
    `tmux.send_keys(pane, message)`.
  - Message format (exact):
    ```
    filepath:start-end
    ```ft
    <code>
    ```
    <instruction>
    ```
    i.e. `string.format("%s:%d-%d\n```%s\n%s\n```\n%s", path, srow, erow, ft,
    table.concat(lines, "\n"), input)`.

## 4. API / interface contracts

| Symbol | Signature | Behavior |
|--------|-----------|----------|
| `require("kiro").setup` | `setup(opts?: { pane?: string, prefix?: string })` | Merge opts into config. |
| `require("kiro").send_file` | `send_file()` | Send `prefix .. relpath` to pane. |
| `require("kiro").ask_selection` | `ask_selection()` | Prompt, send formatted selection block. |
| `tmux.find_pane` | `find_pane(): string?` | First pane id running `kiro`, else nil. |
| `tmux.send_keys` | `send_keys(pane: string, text: string)` | Bracketed-paste text + Enter. |

Config shape (default):
```lua
{ pane = nil, prefix = "look at " }
```

`ask_selection` message example:
```
lua/kiro/tmux.lua:10-14
```lua
function M.find_pane()
  ...
end
```
why does this return nil sometimes?
```

## 5. Acceptance criteria

1. Loading the plugin twice sets `vim.g.loaded_kiro` and does not re-run body.
2. `require("kiro")` exposes callable `setup`, `send_file`, `ask_selection`.
3. `setup({ prefix = "review " })` changes the `send_file` prefix; omitted keys
   keep defaults (`pane = nil`, `prefix = "look at "`).
4. `find_pane()` returns the pane id of a pane whose `pane_current_command`
   contains `kiro`; returns `nil` when none match or tmux errors.
5. `send_keys` issues four ordered `tmux send-keys` calls: paste-start escape,
   text, paste-end escape, then `Enter` — each a separate invocation.
6. `send_file()` on a named buffer sends exactly `prefix .. <relative path>`.
7. `ask_selection()` over lines N..M produces a message matching
   `path:N-M\n```<ft>\n<code>\n```\n<instruction>`.
8. `ask_selection()` aborts silently on cancelled/empty input.
9. Missing `snacks.nvim` → `ask_selection()` notifies and aborts without error.
10. No keymaps are created by the plugin.
11. Works on Neovim 0.9+ (only `vim.system` + stable `vim.api`/`vim.fn` used).

## 6. Out of scope

- Setting keymaps (`<leader>kf`, `<leader>ka`) — user's responsibility; document
  in README only.
- README.md, .gitignore, git init/commit.
- Installing or bundling `snacks.nvim`.
- Spawning/managing `kiro-cli` itself, or `--resume` handling.
- HTTP/socket transport; tmux `send-keys` is the only channel.
- Multi-pane disambiguation UI (first match wins; override via `opts.pane`).
- Async/streaming of kiro output back into Neovim.
