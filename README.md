# kiro.nvim

Send editor context to a running kiro-cli session in a tmux pane without leaving Neovim.

## Features

- **Context Placeholders** - `@this`, `@buffer`, `@visible`, `@diagnostics`
- **Predefined Prompts** - explain, fix, document, test, review, optimize
- **Operator Support** - Vim operator with dot-repeat (`gk`, `gkk`)
- **Select Function** - Choose from all kiro actions
- **Session Commands** - new, select, interrupt, compact, scroll
- **Statusline** - Show kiro connection status
- **Checkhealth** - `:checkhealth kiro` diagnostic

## Requirements

- Neovim 0.9+
- tmux (macOS and Linux; Windows not supported)
- kiro-cli running in a tmux pane
- [snacks.nvim](https://github.com/folke/snacks.nvim) (optional, for enhanced picker)

## Installation

```lua
-- lazy.nvim
{
  "yanralapdy/kiro.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    pane = nil,          -- tmux pane id (e.g. "%0"); nil = auto-detect
    prefix = "look at ", -- prefix used by send_file
    features = {
      context = true,    -- enable @placeholder replacement
      prompts = true,    -- enable predefined prompts
      operator = true,   -- enable operator support
      commands = true,   -- enable session commands
      statusline = true, -- enable statusline component
      checkhealth = true,-- enable :checkhealth
      select = true,     -- enable select function
    },
  },
  keys = {
    { "<leader>kf", function() require("kiro").send_file() end, desc = "Kiro: send file" },
    { "<leader>ka", function() require("kiro").ask_selection() end, desc = "Kiro: ask about selection", mode = { "n", "v" } },
    { "<leader>ks", function() require("kiro").select() end, desc = "Kiro: select action", mode = { "n", "v" } },
    { "<leader>kp", function() require("kiro").select_and_ask() end, desc = "Kiro: select prompt", mode = { "n", "v" } },
    { "gk", function() return require("kiro").operator() end, desc = "Kiro: operator", expr = true },
    { "gkk", function() return require("kiro").operator() .. "_" end, desc = "Kiro: operator (line)", expr = true },
  },
}
```

## Usage

### `<leader>kf` — send file

Sends the current buffer's relative path to kiro:

```
look at lua/kiro/actions.lua
```

### `<leader>ka` — ask about selection

Visually select lines, press `<leader>ka`, type your question. Sends:

```
lua/kiro/tmux.lua:10-14
```lua
function M.find_pane()
  ...
end
```
```

### `<leader>ks` — select action

Open a picker to choose from all kiro actions:
- Send File
- Ask Selection
- Select Prompt
- All predefined prompts

### `<leader>kp` — select prompt

Open a picker to choose a predefined prompt:
- Explain
- Fix
- Document
- Test
- Review
- Optimize

### `gk` / `gkk` — operator

Use as a Vim operator for dot-repeat:

```vim
gkG    " Send from cursor to end of file
gkk    " Send current line
3gk}   " Send next 3 paragraphs
```

## Context Placeholders

Use placeholders in prompts that get replaced with editor context:

| Placeholder | Description |
|-------------|-------------|
| `@this` | Visual selection or cursor position |
| `@buffer` | Entire buffer content |
| `@visible` | Visible text in current window |
| `@diagnostics` | Buffer diagnostics (errors, warnings) |

Example: `Explain @this and its context`

## Predefined Prompts

| Name | Prompt |
|------|--------|
| explain | Explain @this and its context |
| fix | Fix @this and @diagnostics |
| document | Add comments documenting @this |
| test | Add tests for @this |
| review | Review @this for correctness and readability |
| optimize | Optimize @this for performance and readability |

## Session Commands

```lua
require("kiro").command("session.new")        -- Start new session
require("kiro").command("session.select")      -- Select session
require("kiro").command("session.interrupt")   -- Interrupt current task
require("kiro").command("session.compact")     -- Compact session
require("kiro").command("session.page.up")     -- Scroll up
require("kiro").command("session.page.down")   -- Scroll down
require("kiro").command("prompt.submit")       -- Submit prompt
require("kiro").command("prompt.clear")        -- Clear prompt
```

## Statusline

```lua
-- lualine
require("lualine").setup({
  sections = {
    lualine_z = {
      { require("kiro").statusline }
    }
  }
})
```

## Changelog

### 2026-06-11

- **Fixed:** Visual selection now sends the full range instead of just the cursor line. `get_range()` uses `getpos("v")`/`getpos(".")` for live selection data.
- **Fixed:** `@diagnostics` now only includes warnings from the selected range, not the entire buffer.
- **Added:** Deduplication for identical diagnostics on the same line.
- **Added:** `.luarc.json` with `vim` global for Lua language server.

## Compatibility: vim-tmux-navigator

`kiro-cli-term` wraps Neovim in a separate pseudo-terminal, so tmux's process detection (used by [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)) cannot see `nvim` as the foreground process.

**This is handled automatically.** kiro.nvim sets a pane marker (`@kiro_has_nvim`) and patches the tmux bindings on startup so `C-h/j/k/l` correctly navigate Neovim splits inside kiro-cli-term panes. No manual config needed.

## Checkhealth

```vim
:checkhealth kiro
```

Checks:
- tmux installation
- kiro-cli pane detection
- snacks.nvim availability
