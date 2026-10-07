# smart-splits-backend-herdr

[herdr](https://github.com/ogulcancelik/herdr) backend for [smart-splits.nvim](https://github.com/smart-splits-nvim/smart-splits.nvim) v3.

When the cursor reaches the edge of Neovim's window layout, `smart-splits.nvim` hands off to this backend, which moves
focus to (or resizes) the neighboring herdr pane. A companion herdr plugin makes the same keys work from any herdr pane,
not just from inside Neovim.

## Requirements

- Neovim >= 0.11
- `smart-splits.nvim` v3
- herdr >= 0.7.0
- `jq` on `PATH` (herdr plugin only)

## Installation

```lua
{
  'smart-splits-nvim/smart-splits.nvim',
  branch = 'v3',
  opts = {
    mux = {
      backend = 'smart-splits-backend-herdr',
    },
  },
  dependencies = {
    {
      'NWVi/smart-splits-backend-herdr',
      opts = {},
    },
  },
}
```

Outside a herdr session the backend does not detect, and core warns that none of the configured backends detected. Set
`mux.warn_if_unusable = false` to silence it, or only name the backend when herdr is present, so core has nothing
configured to warn about:

```lua
mux = {
  backend = vim.env.HERDR_ENV and 'smart-splits-backend-herdr' or nil,
},
```

Map the keys in Neovim as usual:

```lua
vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)

vim.keymap.set('n', '<A-h>', require('smart-splits').resize_left)
vim.keymap.set('n', '<A-j>', require('smart-splits').resize_down)
vim.keymap.set('n', '<A-k>', require('smart-splits').resize_up)
vim.keymap.set('n', '<A-l>', require('smart-splits').resize_right)
```

## Configuration

```lua
opts = {
  -- Set to false to never use herdr, even inside a herdr session.
  enable = true,
}
```

The backend runs `herdr` from `PATH`, or from `HERDR_BIN_PATH` when it is set. It is detected when `HERDR_ENV` is set
(herdr sets it in every pane) and the binary is executable.

## Behavior

- **Move:** runs `herdr pane focus --direction <dir> --current`.
- **`at_edge = 'wrap'`:** herdr panes never wrap, so the backend returns `false` and core wraps among Neovim windows.
- **`at_edge = 'split'`:** creates a herdr pane. herdr only splits right or down, so splitting left or up splits and
  then swaps the new pane into place.
- **Resize:** `herdr pane resize --amount` takes a split-ratio delta rather than cells, so the cell amount from
  smart-splits is divided by the tab width or height from `herdr pane layout`. Without layout data the delta is `0.02`.

Run `:checkhealth smart-splits` to see whether herdr, the session and `jq` were found.

## herdr plugin

For seamless `<C-h/j/k/l>` that works the same inside and outside Neovim — just like the tmux integration — this repo
ships a small herdr plugin (`herdr-plugin.toml` + `scripts/herdr-navigate.sh`, plus `scripts/herdr-resize.sh` for
`<A-h/j/k/l>` resizing).

It intercepts the keys in herdr, asks `herdr pane process-info` whether the focused pane is running Vim/Neovim, and
either forwards the key into the pane (so Vim can handle its own splits, and at an edge call back into herdr to cross
the pane boundary) or moves herdr focus directly. When the pane is already at an edge in the requested direction (no
neighbor), the key is forwarded back to the running app so shell defaults like `<C-l>` (clear screen) and `<C-h>`
(backspace) keep working.

Link the plugin, replacing the path with where your plugin manager cloned this repo:

```bash
herdr plugin link /path/to/smart-splits-backend-herdr
```

Add the key bindings in `~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "ctrl+h"
type = "plugin_action"
command = "smart-splits-backend-herdr.left"
description = "navigate left (vim/herdr)"

[[keys.command]]
key = "ctrl+j"
type = "plugin_action"
command = "smart-splits-backend-herdr.down"
description = "navigate down (vim/herdr)"

[[keys.command]]
key = "ctrl+k"
type = "plugin_action"
command = "smart-splits-backend-herdr.up"
description = "navigate up (vim/herdr)"

[[keys.command]]
key = "ctrl+l"
type = "plugin_action"
command = "smart-splits-backend-herdr.right"
description = "navigate right (vim/herdr)"

[[keys.command]]
key = "alt+h"
type = "plugin_action"
command = "smart-splits-backend-herdr.resize_left"
description = "resize left (vim/herdr)"

[[keys.command]]
key = "alt+j"
type = "plugin_action"
command = "smart-splits-backend-herdr.resize_down"
description = "resize down (vim/herdr)"

[[keys.command]]
key = "alt+k"
type = "plugin_action"
command = "smart-splits-backend-herdr.resize_up"
description = "resize up (vim/herdr)"

[[keys.command]]
key = "alt+l"
type = "plugin_action"
command = "smart-splits-backend-herdr.resize_right"
description = "resize right (vim/herdr)"
```

Reload herdr:

```bash
herdr server reload-config
```

Each resize press moves the pane border by `SMART_SPLITS_HERDR_RESIZE_CELLS` cells (3 by default).

Other TUIs that own `Ctrl+h/j/k/l` or `Alt+h/j/k/l` themselves (for example `lazygit`, `k9s`) can be added to the
forwarding list by setting `SMART_SPLITS_HERDR_PASSTHROUGH_RE` in herdr's environment to a regex matched against the
lower-cased foreground process name:

```bash
export SMART_SPLITS_HERDR_PASSTHROUGH_RE='^(lazygit|k9s|vi-sql)$'
```

> [!NOTE]
> `Ctrl+H` and Backspace share byte `0x08` unless the kitty keyboard protocol is active. Neovim ≥ 0.10 enables it
> automatically in herdr panes, keeping `<C-h>` distinct. On older Vim you may need to map `<BS>` separately. `Ctrl+L`
> (clear screen) and `Ctrl+K` (kill line) in the shell keep working in single-pane windows thanks to edge passthrough;
> across panes the navigation chord wins (same as in tmux).

## Project Structure

```
.
├── herdr-plugin.toml     # herdr plugin manifest
├── scripts/              # herdr plugin actions
├── lua/smart-splits-backend-herdr/
│   ├── init.lua          # Backend interface
│   ├── config.lua        # Configuration
│   ├── herdr.lua         # herdr CLI wrapper
│   ├── move.lua          # Navigation
│   ├── resize.lua        # Resize logic
│   └── health.lua        # Health check implementation
├── tests/
│   ├── init.lua          # Test initialization
│   ├── helpers.lua       # Test utilities
│   └── core/             # Test specifications
├── justfile              # Command runner
├── .busted               # Busted configuration
├── selene.toml           # Selene configuration
├── .luarc.json           # LuaLS configuration
└── .stylua.toml          # Stylua configuration
```

## License

MIT
