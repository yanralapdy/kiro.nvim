# kiro.nvim

Send editor context to a running kiro-cli session in a tmux pane without leaving Neovim.

## Requirements

- Neovim 0.9+
- tmux (macOS and Linux; Windows not supported)
- kiro-cli running in a tmux pane
- [snacks.nvim](https://github.com/folke/snacks.nvim)

## Installation

```lua
-- lazy.nvim
{
  "yanralapdy/kiro.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    pane = nil,          -- tmux pane id (e.g. "%0"); nil = auto-detect
    prefix = "look at ", -- prefix used by send_file
  },
  keys = {
    { "<leader>kf", function() require("kiro").send_file() end,       desc = "Kiro: send file" },
    { "<leader>ka", function() require("kiro").ask_selection() end,   desc = "Kiro: ask about selection", mode = "v" },
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
why does this return nil sometimes?
```
