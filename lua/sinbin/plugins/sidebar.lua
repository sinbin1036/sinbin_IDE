-- Left area (TASK-016): Files (mini.files, floating at the left top) and Outline
-- (aerial, a full-height left split) take turns; one key switches between them.
-- Project-wide symbols are a separate picker (<Leader>ss in plugins/search.lua).

require("mini.files").setup()
-- Git status colors and letters in the explorer.
require("sinbin.files_git")

local aerial = require("aerial")

local function outline_win()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "aerial" then
      return win
    end
  end
end

local function files_open()
  return MiniFiles.get_explorer_state() ~= nil
end

--- Which one Ctrl+B shows again.
local last = "files"

--- Opens Files at the current file (cwd for unnamed/unsaved buffers), closing Outline.
local function open_files()
  last = "files"
  if outline_win() then
    aerial.close_all()
  end
  local path = vim.api.nvim_buf_get_name(0)
  MiniFiles.open(vim.uv.fs_stat(path) and path or nil)
end

--- Opens Outline for the current file, closing Files.
local function open_outline()
  -- close() returns false while unsynced edits are kept: stay in Files then.
  if files_open() and MiniFiles.close() == false then
    return
  end
  last = "outline"
  aerial.open({ focus = true, direction = "left" })
end

aerial.setup({
  backends = { "lsp", "treesitter", "markdown", "man" },
  -- One Outline that follows the current window, full height at the left edge.
  attach_mode = "global",
  layout = { default_direction = "left", placement = "edge", width = 35, min_width = 25 },
  -- Classes, methods, functions and variables: every symbol kind.
  filter_kind = false,
  show_guides = true,
  -- Cursor follow by line, not column: aerial compares the cursor column too, so the
  -- cursor at column 0 of `    def stop` counted as before `stop` and the previous
  -- symbol was highlighted. <CR> still jumps to the name (selection_range).
  post_parse_symbol = function(_, item)
    item.col = 0
    return true
  end,
  -- Highlight only inside a symbol (blank lines between symbols: none).
  highlight_closest = false,
  nerd_font = true,
  -- Defaults kept: j/k move, h/l fold/unfold, <CR> jump, q close.
  keymaps = {
    ["<Tab>"] = { callback = open_files, desc = "Switch to Files" },
  },
})

-- Outline cursor / highlight row = the innermost symbol containing the cursor, like
-- VS Code. aerial puts them on its "closest" symbol: the last one whose name starts
-- above the cursor, e.g. a variable above the cursor inside a method, or the previous
-- symbol on a `def` line left of the name.
local window = require("aerial.window")
local get_symbol_position = window.get_symbol_position
window.get_symbol_position = function(bufdata, lnum, col, include_hidden)
  local pos = get_symbol_position(bufdata, lnum, col, include_hidden)
  if pos.exact_symbol and pos.exact_symbol ~= pos.closest_symbol then
    local i = 0
    for _, item in bufdata:iter({ skip_hidden = not include_hidden }) do
      i = i + 1
      if item == pos.exact_symbol then
        pos.lnum, pos.closest_symbol = i, item
        break
      end
    end
  end
  return pos
end

-- Files without symbols: one short line instead of aerial's per-backend diagnostics
-- ("lsp (not supported) [...]", ...). `:AerialInfo` still shows them.
local util = require("aerial.util")
local render_centered_text = util.render_centered_text
util.render_centered_text = function(bufnr, text)
  if type(text) == "table" and text[1] == "No symbols" then
    text = { "심볼 없음" }
  end
  return render_centered_text(bufnr, text)
end

-- In the explorer: `g.` makes the directory under the cursor (or the file's directory)
-- the working directory, <Tab> switches to Outline. The explorer itself never changes
-- the working directory. (Not `gc`: that is the built-in comment key and too close to
-- <Leader>gc.)
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  group = vim.api.nvim_create_augroup("sinbin_minifiles", { clear = true }),
  desc = "mini.files: g. sets the working directory, <Tab> switches to Outline",
  callback = function(args)
    vim.keymap.set("n", "g.", function()
      local entry = MiniFiles.get_fs_entry()
      if not entry then
        return
      end
      local dir = entry.fs_type == "directory" and entry.path or vim.fs.dirname(entry.path)
      vim.fn.chdir(dir)
      vim.notify("작업 폴더: " .. vim.fs.normalize(dir), vim.log.levels.INFO)
    end, { buffer = args.data.buf_id, desc = "Set working directory" })
    vim.keymap.set("n", "<Tab>", open_outline, { buffer = args.data.buf_id, desc = "Switch to Outline" })
  end,
})

local map = vim.keymap.set
map("n", "<Leader>fe", function()
  -- Toggle. Checks the state instead of close()'s result: close() returns false when
  -- the user keeps unsynced edits, which must not reopen the explorer.
  if files_open() then
    MiniFiles.close()
    return
  end
  open_files()
end, { desc = "File explorer (toggle)" })
-- Hidden -> open, visible elsewhere -> focus, focused -> close (TASK-016).
map("n", "<Leader>co", function()
  local win = outline_win()
  if win == vim.api.nvim_get_current_win() then
    aerial.close_all()
  elseif win then
    vim.api.nvim_set_current_win(win)
  else
    open_outline()
  end
end, { desc = "Outline" })
-- VS Code Ctrl+B: show / hide the left area (the one used last).
map("n", "<C-b>", function()
  if outline_win() then
    aerial.close_all()
  elseif files_open() then
    MiniFiles.close()
  elseif last == "outline" then
    open_outline()
  else
    open_files()
  end
end, { desc = "Left area (Files / Outline)" })
