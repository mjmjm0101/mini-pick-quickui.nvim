local M = {}

-- Default configuration
local config = {
  separator = " > ",
  show_rtxt = true,
}

--- Setup mini-pick-quickui and register into mini.pick's registry.
---@param opts table|nil  { separator?, show_rtxt? }
function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})
  -- Defer registry injection until after startup.
  -- Access mini.pick via require() rather than the MiniPick global to avoid
  -- depending on the global being set (it requires mini.pick.setup() to exist).
  vim.schedule(function()
    local ok, pick = pcall(require, "mini.pick")
    if ok and pick.registry then
      pick.registry.quickui = M.open
    end
  end)
end

--- Open the QuickUI menu picker.
---@param opts table|nil  MiniPick.start source/window opts
function M.open(opts)
  -- Capture context before MiniPick takes focus so filetype/cwd
  -- reflect the buffer that triggered the picker, not the picker window.
  local exec_opt = {
    filetype = vim.bo.filetype,
    cwd      = vim.fn.getcwd(),
  }

  local entries = require("quickui").get_entries()
  local sep     = config.separator
  local ns      = vim.api.nvim_create_namespace("MiniPickQuickui")

  -- Compute max type width for column alignment.
  local max_type_len = 0
  for _, e in ipairs(entries) do
    max_type_len = math.max(max_type_len, #e.type)
  end

  -- Build picker items.
  -- `text` is used by the matcher for fuzzy search; it contains all
  -- searchable content (type, label segments, and rtxt) as plain text.
  local items = {}
  for _, e in ipairs(entries) do
    local text_parts = { e.type }
    for _, seg in ipairs(e.label) do
      text_parts[#text_parts + 1] = seg
    end
    if e.rtxt then
      text_parts[#text_parts + 1] = e.rtxt
    end

    items[#items + 1] = {
      text   = table.concat(text_parts, " "),
      _type  = e.type,
      _label = e.label,
      _rtxt  = e.rtxt,
      _cmd   = e.cmd,
    }
  end

  --- Apply highlights for a single item row in the picker list.
  ---@param buf_id number  buffer to set extmarks on
  ---@param item   table   picker item ({ text, _type, _label, _rtxt, _cmd })
  ---@param row    number  0-indexed row in the buffer
  local function highlight_item(buf_id, item, row)
    local padded = item._type .. string.rep(" ", max_type_len - #item._type)
    vim.api.nvim_buf_set_extmark(buf_id, ns, row, 0, {
      end_col  = #padded,
      hl_group = "Identifier",
    })

    if config.show_rtxt and item._rtxt then
      local label  = table.concat(item._label, sep)
      -- +2 for the two spaces between type and label columns
      local rtxt_start = #padded + 2 + #label + 2
      vim.api.nvim_buf_set_extmark(buf_id, ns, row, rtxt_start, {
        end_col  = rtxt_start + #item._rtxt,
        hl_group = "Comment",
      })
    end
  end

  --- Render visible items into the picker list buffer.
  ---@param buf_id       number  buffer to write into
  ---@param items_to_show table  items currently visible
  ---@param _query       table   current query tokens (unused but required by API)
  local function show(buf_id, items_to_show, _query)
    local lines = {}
    for _, item in ipairs(items_to_show) do
      local padded = item._type .. string.rep(" ", max_type_len - #item._type)
      local label  = table.concat(item._label, sep)
      local line   = padded .. "  " .. label
      if config.show_rtxt and item._rtxt then
        line = line .. "  " .. item._rtxt
      end
      lines[#lines + 1] = line
    end

    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)

    for i, item in ipairs(items_to_show) do
      highlight_item(buf_id, item, i - 1)
    end
  end

  --- Execute the selected item's command.
  ---@param item table  selected picker item
  local function choose(item)
    if not item then return end
    local cmd = item._cmd
    -- Defer execution so the picker is fully closed before the command runs.
    vim.schedule(function()
      if type(cmd) == "function" then
        cmd(exec_opt)
      else
        vim.fn.feedkeys(
          vim.api.nvim_replace_termcodes(cmd, true, false, true), "n"
        )
      end
    end)
  end

  local source = vim.tbl_deep_extend("force", {
    name    = "QuickUI",
    preview = function() end,
  }, opts and opts.source or {})
  -- Always use our items/show/choose; do not allow opts to override the data source.
  source.items  = items
  source.show   = show
  source.choose = choose

  local start_opts = vim.tbl_deep_extend("force", opts or {}, { source = source })

  require("mini.pick").start(start_opts)
end

return M
