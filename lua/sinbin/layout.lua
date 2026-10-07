-- VS Code style window layout (TASK-016):
--   left    Outline sidebar (aerial), full height. Files (mini.files) float over it.
--   right   AI Agent terminals, full height
--   bottom  panel under the editor area only: one window switching between Terminal /
--           Run tabs (sinbin.terminal), the debug panel (dap-view) beside it
-- Bottom windows open full width (split below win = -1); whenever a new window breaks
-- the shape, the side columns are moved back out with <C-w>H / <C-w>L.
-- Also: file path winbar on editor windows, closing a tab without closing its window.

local M = {}

function M.bottom_height()
  return math.max(8, math.floor(vim.o.lines * 0.3))
end

function M.right_width()
  return math.max(60, math.floor(vim.o.columns * require("sinbin.settings").get("agent_width") / 100))
end

--- Marks `win` as the bottom panel or a right column window (set by sinbin.terminal).
--- @param win integer
--- @param region "bottom"|"right"
function M.mark(win, region)
  vim.w[win].sinbin_region = region
  -- The terminal to put back if a file is opened in this window (see guard_area).
  vim.w[win].sinbin_term = vim.api.nvim_win_get_buf(win)
  if region == "bottom" then
    vim.w[win].sinbin_height = vim.api.nvim_win_get_height(win)
  else
    vim.w[win].sinbin_width = vim.api.nvim_win_get_width(win)
  end
end

--- @return "left"|"right"|"bottom"|"debug"|nil
local function region(win)
  if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "aerial" then
    return "left"
  end
  if vim.w[win].dapview_win or vim.w[win].dapview_win_term then
    return "debug"
  end
  return vim.w[win].sinbin_region
end

local function area_win(area)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.w[win].sinbin_region == area then
      return win
    end
  end
end

--- The bottom panel window of the current tab, if open.
function M.panel_win()
  return area_win("bottom")
end

--- The right area window (shell / AI Agents) of the current tab, if open.
function M.right_win()
  return area_win("right")
end

--- Sets the open right area to right_width() (settings panel), keeping it from then on.
function M.resize_right()
  local win = M.right_win()
  if win then
    vim.api.nvim_win_set_width(win, M.right_width())
    vim.w[win].sinbin_width = vim.api.nvim_win_get_width(win)
  end
end

local function plain_wins()
  return vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == ""
  end, vim.api.nvim_tabpage_list_wins(0))
end

--- Gives the bottom panel back the height it had (set when opened or by the user)
--- after a new window (:copen, :help) took rows from it.
local function restore_panel_height()
  local panel = M.panel_win()
  local want = panel and vim.w[panel].sinbin_height
  if want and vim.api.nvim_win_get_height(panel) < want then
    vim.api.nvim_win_set_height(panel, want)
  end
end

--- Fixes the current tab's layout: Outline first and Agent windows last among the
--- top-level columns. Sizes the user set are kept.
function M.normalize()
  local wins = plain_wins()
  if #wins < 2 then
    return
  end

  local left, rights, sizes = nil, {}, {}
  for _, w in ipairs(wins) do
    local r = region(w)
    if r == "left" and not vim.w[w].sinbin_width then
      vim.w[w].sinbin_width = vim.api.nvim_win_get_width(w)
    end
    if r == "left" then
      left = w
    elseif r == "right" then
      rights[#rights + 1] = w
    end
    if r then
      sizes[w] = { vim.api.nvim_win_get_width(w), vim.api.nvim_win_get_height(w), r }
    end
  end

  -- Top-level columns: leaves directly under the root row.
  local top = {}
  local root = vim.fn.winlayout()
  if root[1] == "row" then
    for i, child in ipairs(root[2]) do
      if child[1] == "leaf" then
        top[child[2]] = i
      end
    end
  end
  local n = root[1] == "row" and #root[2] or 0

  local moved = false
  local function move(w, cmd)
    vim.api.nvim_win_call(w, function() vim.cmd.wincmd(cmd) end)
    moved = true
  end
  if left and top[left] ~= 1 then
    move(left, "H")
  end
  for _, w in ipairs(rights) do
    if not top[w] or top[w] <= n - #rights then
      move(w, "L")
    end
  end
  if not moved then
    restore_panel_height()
    return
  end

  for w, s in pairs(sizes) do
    if vim.api.nvim_win_is_valid(w) then
      if s[3] == "bottom" or s[3] == "debug" then
        vim.api.nvim_win_set_height(w, s[2])
      else
        vim.api.nvim_win_set_width(w, s[1])
      end
    end
  end
  restore_panel_height()
end

-- New windows (terminals, dap-view, aerial) get their buffer after WinNew: check once
-- everything has settled.
local pending = false
local group = vim.api.nvim_create_augroup("sinbin_layout", { clear = true })
vim.api.nvim_create_autocmd("WinNew", {
  group = group,
  desc = "Keep the side columns full height",
  callback = function()
    if pending then
      return
    end
    pending = true
    vim.schedule(function()
      pending = false
      M.normalize()
    end)
  end,
})

-- The panel height to restore follows the user's own resizing only: a resize with the
-- same number of windows as before (a new or closed window changes the count).
local win_count = {}
vim.api.nvim_create_autocmd("WinResized", {
  group = group,
  desc = "Remember the panel height / side column widths the user set",
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    local n = #plain_wins()
    if win_count[tab] == n then
      for _, w in ipairs(vim.v.event.windows) do
        if vim.api.nvim_win_is_valid(w) then
          local r = region(w)
          if r == "bottom" then
            vim.w[w].sinbin_height = vim.api.nvim_win_get_height(w)
          elseif r == "left" or r == "right" then
            vim.w[w].sinbin_width = vim.api.nvim_win_get_width(w)
          end
        end
      end
    end
    win_count[tab] = n
  end,
})

------------------------------------------------------------------------------
-- Empty editor (TASK-022): a code window without a file shows key hints in a read-only
-- scratch buffer, like VS Code's empty editor, instead of an empty [No Name] buffer
-- that takes typing. Opening a file replaces it (bufhidden = wipe).

local EMPTY_FT = "sinbinempty"
local HINTS = {
  { "Space f f", "파일 찾기" },
  { "Space f e", "파일 탐색기" },
  { "Space s g", "내용 검색" },
  { "Space a c", "Claude Code" },
  { ":Home", "시작 화면" },
}
local empty_ns = vim.api.nvim_create_namespace("sinbin_empty_editor")

--- Draws the hints centered in `win`.
local function render_empty(buf, win)
  local key_width = 0
  for _, h in ipairs(HINTS) do
    key_width = math.max(key_width, #h[1])
  end
  local rows, block = {}, 0
  for _, h in ipairs(HINTS) do
    local text = h[1] .. (" "):rep(key_width - #h[1] + 4) .. h[2]
    rows[#rows + 1] = text
    block = math.max(block, vim.fn.strdisplaywidth(text))
  end
  local left = (" "):rep(math.max(0, math.floor((vim.api.nvim_win_get_width(win) - block) / 2)))
  local lines = {}
  for _ = 1, math.max(0, math.floor((vim.api.nvim_win_get_height(win) - #rows) / 2)) do
    lines[#lines + 1] = ""
  end
  local first = #lines
  for _, r in ipairs(rows) do
    lines[#lines + 1] = left .. r
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, empty_ns, 0, -1)
  for i, h in ipairs(HINTS) do
    local row = first + i - 1
    vim.api.nvim_buf_set_extmark(buf, empty_ns, row, #left, { end_col = #left + #h[1], hl_group = "Special" })
    vim.api.nvim_buf_set_extmark(buf, empty_ns, row, #left + #h[1], { end_col = #lines[row + 1], hl_group = "Comment" })
  end
end

--- A new empty editor buffer, to show in a code window.
--- @return integer buf
function M.empty_buf()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = EMPTY_FT
  vim.bo[buf].modifiable = false
  return buf
end

--- Shows an empty editor in `win` (0 = current window).
function M.show_empty(win)
  vim.api.nvim_win_set_buf(win, M.empty_buf())
end

local function refresh_empty()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == EMPTY_FT then
      -- [0]: local to this buffer in the window; a file opened here gets its own.
      local wo = vim.wo[win][0]
      wo.number = false
      wo.relativenumber = false
      wo.cursorline = false
      wo.signcolumn = "no"
      wo.foldcolumn = "0"
      wo.list = false
      wo.wrap = false
      wo.statuscolumn = ""
      render_empty(buf, win)
    end
  end
end

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinResized", "VimResized" }, {
  group = group,
  desc = "Empty editor: hints centered in the window",
  callback = refresh_empty,
})

-- `nvim .`: the directory buffer would be the empty, writable code window (the folder
-- itself opens in mini.files). An empty editor takes its place.
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  desc = "Empty editor instead of the directory buffer",
  callback = function()
    vim.schedule(function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local name = vim.api.nvim_buf_get_name(buf)
        if vim.api.nvim_win_get_config(win).relative == "" and name ~= "" and vim.fn.isdirectory(name) == 1 then
          M.show_empty(win)
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end
    end)
  end,
})

-- Closing the last code window (:q) while the Outline, panel or Agent stay open leaves
-- an empty code window in its place, like VS Code's empty editor. Not when several
-- windows close at once (:only, closing a tab).
local closed, closed_code = 0, false
local function is_code(win)
  return vim.api.nvim_win_get_config(win).relative == "" and region(win) == nil
end

--- Opens a code window for `buf` where code goes: above the bottom panel, else right
--- of the Outline, else left of the right area.
--- @return integer? win
local function open_code_window(buf)
  local left, right
  for _, w in ipairs(plain_wins()) do
    local r = region(w)
    left = left or (r == "left" and w) or nil
    right = right or (r == "right" and w) or nil
  end
  local panel = M.panel_win()
  local opts = panel and { split = "above", win = panel }
    or left and { split = "right", win = left }
    or right and { split = "left", win = right }
  if not opts then
    return
  end
  local win = vim.api.nvim_open_win(buf, true, opts)
  -- The side columns and the panel took the closed window's space: back to their own
  -- sizes (set when opened or by the user).
  for _, w in pairs({ left = left, right = right }) do
    if vim.w[w].sinbin_width then
      vim.api.nvim_win_set_width(w, vim.w[w].sinbin_width)
    end
  end
  if panel and vim.w[panel].sinbin_height then
    vim.api.nvim_win_set_height(panel, vim.w[panel].sinbin_height)
  end
  return win
end

local function ensure_code_window()
  local wins = plain_wins()
  if #wins == 0 or vim.tbl_contains(vim.tbl_map(is_code, wins), true) then
    return
  end
  open_code_window(M.empty_buf())
end

-- :q in the last code window of the tab closes the Outline, panel, Agent area and
-- floats first, so it quits Neovim (or closes the tab page) instead of leaving only
-- terminals. Unsaved files still stop it: with the areas closed the code window is the
-- last one, and Neovim refuses to quit (E37 current file, E162 another file).
vim.api.nvim_create_autocmd("QuitPre", {
  group = group,
  desc = ":q in the last code window quits",
  callback = function()
    local cur = vim.api.nvim_get_current_win()
    if not is_code(cur) then
      return
    end
    local others = {}
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if w ~= cur then
        if is_code(w) then
          return -- another code window stays: an ordinary window close
        end
        others[#others + 1] = w
      end
    end
    for _, w in ipairs(others) do
      pcall(vim.api.nvim_win_close, w, true)
    end
  end,
})

vim.api.nvim_create_autocmd("WinClosed", {
  group = group,
  desc = "Keep a code window",
  callback = function(args)
    local win = tonumber(args.match)
    if not (win and vim.api.nvim_win_is_valid(win)) or vim.api.nvim_win_get_config(win).relative ~= "" then
      return
    end
    closed = closed + 1
    if is_code(win) then
      closed_code = true
      -- Still the sizes before this close: what open_code_window() gives back.
      for _, w in ipairs(plain_wins()) do
        local r = region(w)
        if r == "left" or r == "right" then
          vim.w[w].sinbin_width = vim.api.nvim_win_get_width(w)
        end
      end
    end
    if closed > 1 then
      return
    end
    vim.schedule(function()
      local single = closed == 1 and closed_code
      closed, closed_code = 0, false
      if single and vim.v.exiting == vim.NIL then
        ensure_code_window()
      end
    end)
  end,
})

------------------------------------------------------------------------------
-- The bottom panel and the right area hold terminals only, like VS Code's terminal
-- panel. A file opened there (a tab click, a picker, mini.files, <C-o> while the cursor
-- is in a terminal) moves to the last used code window and the area gets its terminal
-- back.

local last_code
vim.api.nvim_create_autocmd("WinEnter", {
  group = group,
  desc = "Remember the last code window",
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if is_code(win) then
      last_code = win
    end
  end,
})

local function code_window()
  if last_code and vim.api.nvim_win_is_valid(last_code) and is_code(last_code)
    and vim.api.nvim_win_get_tabpage(last_code) == vim.api.nvim_get_current_tabpage() then
    return last_code
  end
  for _, w in ipairs(plain_wins()) do
    if is_code(w) then
      return w
    end
  end
end

local function guard_area(win, buf)
  local area = vim.w[win].sinbin_region
  if area ~= "bottom" and area ~= "right" then
    return
  end
  if vim.bo[buf].buftype == "terminal" then
    vim.w[win].sinbin_term = buf
    return
  end
  -- After the command that opened the file has finished with the window.
  vim.schedule(function()
    if not (vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf)) or vim.api.nvim_win_get_buf(win) ~= buf then
      return
    end
    -- sinbin.terminal shows a new buffer first and starts the terminal in it after.
    if vim.bo[buf].buftype == "terminal" then
      vim.w[win].sinbin_term = buf
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(win)
    local term = vim.w[win].sinbin_term
    if term and vim.api.nvim_buf_is_valid(term) then
      vim.api.nvim_win_set_buf(win, term)
    elseif #plain_wins() > 1 then
      vim.api.nvim_win_close(win, true)
    end
    local target = code_window()
    if target then
      vim.api.nvim_win_set_buf(target, buf)
      vim.api.nvim_set_current_win(target)
    else
      target = open_code_window(buf)
    end
    if target then
      pcall(vim.api.nvim_win_set_cursor, target, cursor)
    end
  end)
end

------------------------------------------------------------------------------
-- winbar: file path relative to the working directory as `a > b > c.lua` on editor
-- windows; the Terminal / Run tabs on the bottom panel.

function M.winbar()
  local path = vim.fn.expand("%:~:.")
  if path == "" then
    return ""
  end
  local parts = vim.split((path:gsub("\\", "/")), "/", { trimempty = true })
  for i, p in ipairs(parts) do
    parts[i] = (p:gsub("%%", "%%%%"))
  end
  local name = table.remove(parts)
  local icon, icon_hl = MiniIcons.get("file", name)
  table.insert(parts, ("%%#%s#%s %%#WinBar#%s"):format(icon_hl, icon, name))
  return "%#WinBarNC# " .. table.concat(parts, " > ") .. (vim.bo.modified and " %#WinBarNC#●" or "")
end

local FILE_WINBAR = "%{%v:lua.require'sinbin.layout'.winbar()%}"
local PANEL_WINBAR = "%{%v:lua.require'sinbin.terminal'.panel_winbar()%}"
local RIGHT_WINBAR = "%{%v:lua.require'sinbin.terminal'.right_winbar()%}"

local function update_winbar(win)
  -- Floats have none, except the full screen right area (its tabs).
  if vim.api.nvim_win_get_config(win).relative ~= "" and not vim.w[win].sinbin_zoom then
    return
  end
  local r = region(win)
  if r == "debug" then
    return -- dap-view draws its own section tabs there
  end
  local value = ""
  if r == "bottom" then
    value = PANEL_WINBAR
  elseif r == "right" then
    value = RIGHT_WINBAR
  elseif not r then
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    -- Not for directory buffers (`nvim .`, opened in mini.files).
    if vim.bo[buf].buftype == "" and name ~= "" and vim.fn.isdirectory(name) == 0 then
      value = FILE_WINBAR
    end
  end
  -- [0]: local to this window, so new windows do not inherit it.
  vim.wo[win][0].winbar = value
end
M.update_winbar = update_winbar

vim.api.nvim_create_autocmd({ "BufWinEnter", "BufFilePost", "OptionSet" }, {
  group = group,
  desc = "Winbar: file path / panel tabs",
  callback = function(args)
    if args.event == "OptionSet" and args.match ~= "buftype" then
      return
    end
    for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
      if args.event == "BufWinEnter" then
        guard_area(win, args.buf)
      end
      update_winbar(win)
    end
  end,
})

------------------------------------------------------------------------------
-- Closing a tab (buffer) keeps every window: windows showing it switch to their
-- previous file first.

--- @param buf? integer 0/nil = current buffer
function M.close_buffer(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if vim.bo[buf].modified then
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    -- ASCII hotkeys: Korean ones (&저장) cannot be typed on an English layout.
    local choice = vim.fn.confirm(("저장 안 됨: %s"):format(name ~= "" and name or "[No Name]"), "저장(&S)\n버리기(&D)\n취소(&C)", 3)
    if choice == 1 then
      vim.api.nvim_buf_call(buf, function() vim.cmd.write() end)
    elseif choice ~= 2 then
      return
    end
  end

  local others = vim.tbl_filter(function(b)
    return b ~= buf and vim.bo[b].buflisted
  end, vim.api.nvim_list_bufs())
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local alt = vim.api.nvim_win_call(win, function() return vim.fn.bufnr("#") end)
    local next_buf = (alt > 0 and alt ~= buf and vim.bo[alt].buflisted) and alt or others[#others]
    vim.api.nvim_win_set_buf(win, next_buf or M.empty_buf())
  end
  vim.api.nvim_buf_delete(buf, { force = true })
end

return M
