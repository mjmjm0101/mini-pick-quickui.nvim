# mini-pick-quickui.nvim

A [mini.pick](https://github.com/nvim-mini/mini.pick) integration for [quickui.nvim](https://github.com/mjmjm0101/quickui.nvim).

Exposes your quickui menubar structure as a fuzzy-searchable mini.pick picker.
Search by your own menu names and categories — not by plugin command names.

```
File      New File
File      Recent > foo.lua
Git       Hunk > Stage        stage hunk under cursor
LSP       Symbol > Rename     rename symbol at cursor
```

## 🔍 Why combine quickui.nvim with a search UI?

Search-based workflows are powerful — but they assume you remember what to search for.

quickui.nvim organizes your tools into a structure you can navigate.
By combining it with a search UI, you can search over your own categorized actions,
not just command names.

This solves the common frustration of "not knowing what to type"
and turns search into a complement to structure — not a replacement.

## Requirements

- Neovim 0.10+
- [quickui.nvim](https://github.com/mjmjm0101/quickui.nvim)
- [mini.pick](https://github.com/nvim-mini/mini.pick)

## Installation

### lazy.nvim

```lua
{
  "mjmjm0101/mini-pick-quickui.nvim",
  dependencies = {
    "mjmjm0101/quickui.nvim",
    "nvim-mini/mini.pick",
  },
  config = function()
    require("mini-pick-quickui").setup()
  end,
}
```

### packer.nvim

```lua
use({
  "mjmjm0101/mini-pick-quickui.nvim",
  requires = {
    "mjmjm0101/quickui.nvim",
    "nvim-mini/mini.pick",
  },
  config = function()
    require("mini-pick-quickui").setup()
  end,
})
```

### vim-plug

```vim
Plug 'mjmjm0101/quickui.nvim'
Plug 'nvim-mini/mini.pick'
Plug 'mjmjm0101/mini-pick-quickui.nvim'
```

Then in your Lua config:

```lua
require("mini-pick-quickui").setup()
```

## Configuration

```lua
require("mini-pick-quickui").setup({
  separator = " > ",  -- separator between label segments (default: " > ")
  show_rtxt = true,   -- show rtxt hints in the picker (default: true)
                      -- rtxt is always included in fuzzy search regardless
})
```

## Usage

```lua
require("mini-pick-quickui").open()
```

Or via `:Pick` (registered by `setup()`):

```vim
:Pick quickui
```

Bind it to a key:

```lua
vim.keymap.set("n", "<leader>/", require("mini-pick-quickui").open)
```

mini.pick options can be passed directly:

```lua
require("mini-pick-quickui").open({
  window = { config = { width = 80 } },
})
```

## Highlight Groups

The picker uses the following Neovim highlight groups for column styling.

| Column | Highlight group |
|---|---|
| Type (e.g. `File`, `Git`) | `Identifier` |
| Label | Default |
| rtxt hint | `Comment` |

## How it works

The picker calls `require("quickui").get_entries()`, which flattens the menubar
registry into a list of `{ type, label, rtxt, cmd }` entries evaluated against
the current Neovim context (filetype, cwd). Conditions and filetype filters are
applied before the list is returned, so only items valid for the current buffer
are shown.

Selecting an entry executes the associated command:
- String commands are sent via `feedkeys`.
- Function commands are called with the context captured at picker-open time,
  so `filetype` and `cwd` reflect the buffer that triggered the picker.

## License

MIT
