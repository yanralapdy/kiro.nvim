# kiro.nvim — Handoff

## Goal

Build a Neovim plugin (`kiro.nvim`) that lets you send context from Neovim into an already-running `kiro-cli` session in a tmux pane — without leaving your editor.

Two keymaps:
- `<leader>kf` — sends current buffer file to kiro ("look at `<path>`")
- `<leader>ka` — visual selection + snacks.input dialog → sends file path, line range, selected code block, and user's typed instruction to kiro

---

## Decisions Made

| Decision | Choice | Reason |
|----------|--------|--------|
| Communication | `tmux send-keys` to existing pane | kiro-cli has no HTTP API; `--resume` wouldn't show output in the visible pane |
| Pane targeting | Auto-detect pane running `kiro-cli`, config override via `opts.pane` | Zero-config for common case |
| `<leader>kf` format | `look at <relative_path>` (prefix configurable) | Simple, kiro reads the file itself |
| `<leader>ka` format | `filepath:start-end\n```ft\n<code>\n```\n<user text>` | Line range + inline code + instruction |
| Multi-line sending | Bracketed paste (`\x1b[200~` … `\x1b[201~`) then Enter | Prevents newlines triggering submit prematurely |
| Dialog | `Snacks.input()`, single-line, cancel = abort silently | Matches snacks.nvim pattern |
| Plugin name | `kiro.nvim`, module `require("kiro")` | Standard `*.nvim` convention |
| Location | `~/sites/lua/kiro.nvim` standalone repo | Publishable, local dev via lazy `dir =` |
| Keymaps | NOT set by plugin — user sets their own | Standard plugin etiquette |
| Config shape | `{ pane = nil, prefix = "look at " }` | Minimal surface |

---

## Current State

- Directory created: `~/sites/lua/kiro.nvim/`
- This handoff document written
- **Nothing else exists yet** — no Lua files, no git repo, no spec

The subagent pipeline (architect → builder → reviewer → documenter) was started twice but cancelled by the user before completion.

---

## Next Steps

1. **Scaffold files** — create the directory structure:
   ```
   ~/sites/lua/kiro.nvim/
   ├── plugin/kiro.lua          # entry point + guard
   ├── lua/kiro/init.lua        # setup(), config, re-exports
   ├── lua/kiro/tmux.lua        # find_pane(), send_keys()
   ├── lua/kiro/actions.lua     # send_file(), ask_selection()
   ├── README.md
   └── .gitignore
   ```

2. **Implement `lua/kiro/tmux.lua`**:
   - `find_pane()` → runs `tmux list-panes -a -F "#{pane_id} #{pane_current_command}"`, returns first pane_id where command contains `kiro`
   - `send_keys(pane, text)` → sends bracketed paste: `\x1b[200~` + text + `\x1b[201~` + Enter as separate `tmux send-keys` calls

3. **Implement `lua/kiro/actions.lua`**:
   - `send_file()` → gets current buffer path (relative), calls `send_keys(pane, prefix .. path)`
   - `ask_selection()` → gets visual marks `'<` and `'>`, extracts lines + filetype + filepath, opens `Snacks.input()`, on confirm calls `send_keys(pane, formatted_message)`

4. **Implement `lua/kiro/init.lua`** — `setup()` merges opts into config, re-exports actions

5. **Implement `plugin/kiro.lua`** — guard against double-load, call nothing (keymaps are user's responsibility)

6. **Git init** — `git init`, initial commit

7. **README** — install via lazy.nvim, setup block, example keymaps, format examples

---

## Gotchas

- **Bracketed paste**: tmux `send-keys` requires the escape sequences as literal strings. Use `\x1b[200~` (paste start) and `\x1b[201~` (paste end) as separate `send-keys` invocations, then a final `Enter`. Do NOT try to embed them all in one shell argument.
- **Visual marks**: `nvim_buf_get_mark(0, "<")` and `nvim_buf_get_mark(0, ">")` return `{row, col}` (0-indexed row). Line numbers shown to user are 1-indexed. `nvim_buf_get_lines` uses 0-indexed start/end.
- **`ask_selection` must be called from normal mode** after exiting visual — Neovim exits visual mode before executing the keymap callback, so marks `'<` and `'>` are already set correctly.
- **snacks.input availability**: guard with `pcall(require, "snacks")` and notify user if missing.
- **`vim.system()`** requires Neovim 0.9+. Use `{text = true}` option and check exit code.
- **kiro-cli binary is at** `~/.local/bin/kiro-cli` on this machine.
- The subagent pipeline approach works — just run it uninterrupted. The pipeline prompt is in the conversation history.
