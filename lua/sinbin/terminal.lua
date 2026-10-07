-- Terminal windows (TASK-012), built on jobstart(term = true).
-- Two areas of one window each, whose winbar lists their terminals as tabs (TASK-016):
-- the bottom panel (numbered shells, Run) and the right area (a shell, AI Agent CLIs,
-- TASK-015). Also one floating shell terminal and one-off command terminals (lazygit).
-- Hiding a terminal keeps its process running.

local layout = require("sinbin.layout")

local M = {}

--- @class sinbin.Term
--- @field buf integer
--- @field name string
--- @field kind? "split"|"float"|"right" where it is shown again (nil: bottom panel)
--- @field done? boolean the command of an exec() terminal has exited

--- @type table<string, sinbin.Term>
local terms = {}

local function shell_cmd()
  -- Set per OS by the Platform Layer; otherwise the 'shell' option.
  -- Passed as a list: a string would be run through 'shell' + 'shellcmdflag' again.
  return require("sinbin.platform").terminal_shell or { (vim.o.shell:gsub('^"(.*)"$', "%1")) }
end

local function float_config()
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.85)
  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  }
end

--- Window options of a terminal window, set again whenever it shows another buffer.
local function prepare(win)
  vim.wo[win][0].number = false
  vim.wo[win][0].relativenumber = false
  vim.wo[win][0].signcolumn = "no"
  layout.update_winbar(win)
end

--- Opens a window for `buf` (or, for the bottom panel and the right area, reuses the
--- area's open window) and returns its id.
--- @param buf integer
--- @param kind "split"|"float"|"right"
local function open_window(buf, kind)
  local win
  if kind == "float" then
    win = vim.api.nvim_open_win(buf, true, float_config())
  elseif kind == "right" then
    win = layout.right_win()
    if win then
      vim.api.nvim_win_set_buf(win, buf)
      vim.api.nvim_set_current_win(win)
    else
      win = vim.api.nvim_open_win(buf, true, {
        split = "right",
        win = -1, -- full height at the right of the tab
        width = layout.right_width(),
      })
      vim.wo[win].winfixwidth = true
      layout.mark(win, "right")
    end
  else
    win = layout.panel_win()
    if win then
      vim.api.nvim_win_set_buf(win, buf)
      vim.api.nvim_set_current_win(win)
    else
      -- Full width at the bottom; sinbin.layout moves the side columns back out.
      win = vim.api.nvim_open_win(buf, true, { split = "below", win = -1, height = layout.bottom_height() })
      vim.wo[win].winfixheight = true
      layout.mark(win, "bottom")
    end
  end
  prepare(win)
  return win
end

local function is_alive(term)
  return term and vim.api.nvim_buf_is_valid(term.buf)
end

--- Window showing `buf` in the current tab, if any.
local function find_window(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

--- Starts `cmd` in a new terminal buffer shown in a new window. With `background` the
--- cursor goes back to the window it came from instead of into the terminal.
--- @param cmd string|string[]
--- @param kind "split"|"float"|"right"
--- @param on_exit? fun(buf: integer)
--- @param cwd? string
--- @param background? boolean
local function start(cmd, kind, on_exit, cwd, background)
  local prev = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, false)
  open_window(buf, kind)
  vim.fn.jobstart(cmd, {
    term = true,
    cwd = cwd,
    on_exit = function()
      vim.schedule(function()
        if on_exit then
          on_exit(buf)
        end
      end)
    end,
  })
  if background then
    vim.api.nvim_set_current_win(prev)
  else
    vim.cmd.startinsert()
  end
  return buf
end

--- @param area "bottom"|"right"
local function in_area(term, area)
  if area == "right" then
    return term.kind == "right"
  end
  return term.kind == nil or term.kind == "split"
end

--- Terminals of an area in tab order: numbered shells (bottom) / the shell (right)
--- first, then the rest by id.
--- @param area "bottom"|"right"
--- @return { id: string, name: string, buf: integer }[]
local function area_terms(area)
  local items = {}
  for id, term in pairs(terms) do
    if is_alive(term) and in_area(term, area) then
      items[#items + 1] = { id = id, name = term.name, buf = term.buf }
    end
  end
  table.sort(items, function(a, b)
    local na, nb = tonumber(a.id), tonumber(b.id)
    if na and nb then
      return na < nb
    end
    if na or nb then
      return na ~= nil
    end
    if (a.id == "side") ~= (b.id == "side") then
      return a.id == "side"
    end
    return a.id < b.id
  end)
  return items
end

local function panel_terms()
  return area_terms("bottom")
end

--- Closes every window showing `buf` and deletes it. The bottom panel and the right
--- area show another of their terminals instead of closing, if there is one.
local function close_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    local area = vim.w[win].sinbin_region
    local other = (area == "bottom" or area == "right")
      and vim.tbl_filter(function(t) return t.buf ~= buf end, area_terms(area))[1]
    if other then
      vim.api.nvim_win_set_buf(win, other.buf)
      prepare(win)
    -- The last window of the editor cannot be closed; switch it to an empty buffer instead.
    elseif #vim.api.nvim_list_wins() > 1 then
      vim.api.nvim_win_close(win, true)
    else
      vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
    end
  end
  vim.api.nvim_buf_delete(buf, { force = true })
end

--- Shows terminal `id` (a shell, or the program `opts.cmd`: a shell command line, run
--- like Run commands so Windows npm shims work). One key for open / move / hide
--- (TASK-016): hidden -> shown and focused, visible elsewhere -> focused, focused ->
--- hidden.
--- @param id string
--- @param kind "split"|"float"|"right"
--- With `opts.background` a new terminal starts without taking the cursor.
--- @param opts? { cmd?: string, cwd?: string, name?: string, background?: boolean }
function M.toggle(id, kind, opts)
  opts = opts or {}
  local term = terms[id]
  if is_alive(term) then
    local win = find_window(term.buf)
    if win == vim.api.nvim_get_current_win() then
      vim.api.nvim_win_close(win, true)
    elseif win then
      vim.api.nvim_set_current_win(win)
      vim.cmd.startinsert()
    else
      open_window(term.buf, kind)
      vim.cmd.startinsert()
    end
    return
  end
  local cmd = shell_cmd()
  if opts.cmd then
    local exec = require("sinbin.platform").terminal_exec
    cmd = exec and exec(opts.cmd) or opts.cmd
  end
  local buf = start(cmd, kind, function(b)
    -- `exit` in the shell / the program quit: drop the window and buffer. Not the
    -- entry when M.close() already replaced it with a new terminal of the same id.
    if terms[id] and terms[id].buf == b then
      terms[id] = nil
    end
    close_buffer(b)
  end, opts.cwd, opts.background)
  terms[id] = { buf = buf, kind = kind, name = opts.name or (kind == "float" and "float" or ("Terminal " .. id)) }
end

--- Whether terminal `id` is running.
function M.is_running(id)
  return is_alive(terms[id])
end

--- Whether the exec() command in terminal `id` has not exited yet (Run status).
--- A flag, not jobwait(): the statusline calls this, and jobwait() would run pending
--- autocommands (TermClose) while the statusline is drawn.
function M.job_running(id)
  local term = terms[id]
  return is_alive(term) and term.done == false
end

-- Click ids: bottom panel tabs 1.., right area tabs RIGHT_CLICK + 1..
local RIGHT_CLICK = 1000

--- Area winbar: its terminals as tabs, the shown one highlighted. Clickable.
--- @param area "bottom"|"right"
function M.area_winbar(area)
  local shown = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
  local parts = {}
  for i, t in ipairs(area_terms(area)) do
    local hl = t.buf == shown and "%#TabLineSel#" or "%#TabLine#"
    -- The Run command line is long; it shows inside the terminal.
    local label = t.id == "run" and "Run" or t.name
    local click = (area == "right" and RIGHT_CLICK or 0) + i
    parts[#parts + 1] = ("%s%%%d@v:lua.SinbinPanelClick@ %s %%X"):format(hl, click, label:gsub("%%", "%%%%"))
  end
  return table.concat(parts, "") .. "%#TabLineFill#"
end

function M.panel_winbar()
  return M.area_winbar("bottom")
end

function M.right_winbar()
  return M.area_winbar("right")
end

--- Click on an area tab (winbar `%@`): show that terminal.
function _G.SinbinPanelClick(index)
  local right = index > RIGHT_CLICK
  local t = area_terms(right and "right" or "bottom")[right and index - RIGHT_CLICK or index]
  if t then
    vim.schedule(function() M.show(t.id) end)
  end
end

--- Shows terminal `id` (where it was opened) if hidden, focuses it in terminal mode.
--- @return boolean false when it is not running
function M.focus(id)
  local term = terms[id]
  if not is_alive(term) then
    return false
  end
  local win = find_window(term.buf)
  if win then
    vim.api.nvim_set_current_win(win)
  else
    open_window(term.buf, term.kind or "split")
  end
  vim.cmd.startinsert()
  return true
end

--- Types `text` into terminal `id` as if from the keyboard (no Enter).
--- @return boolean false when it is not running
function M.send(id, text)
  local term = terms[id]
  if not is_alive(term) then
    return false
  end
  vim.api.nvim_chan_send(vim.bo[term.buf].channel, text)
  return true
end

--- Runs a command in a floating terminal that closes when the command exits.
--- @param cmd string[]
--- @param opts? { cwd?: string, on_exit?: fun() }
function M.run_float(cmd, opts)
  opts = opts or {}
  start(cmd, "float", function(buf)
    close_buffer(buf)
    if opts.on_exit then
      opts.on_exit()
    end
  end, opts.cwd)
end

--- Runs a shell command line in terminal `id` (bottom split), replacing whatever ran
--- there before. The buffer stays after the command ends so its output can be read.
--- With `focus`, the cursor moves into the terminal ready for input (programs reading
--- stdin); otherwise focus returns to the window it came from (dev servers).
--- @param id string
--- @param cmd string shell command line
--- @param opts? { cwd?: string, name?: string, focus?: boolean }
function M.exec(id, cmd, opts)
  opts = opts or {}
  local prev = vim.api.nvim_get_current_win()
  local old = terms[id]
  local win = is_alive(old) and find_window(old.buf) or nil

  local buf = vim.api.nvim_create_buf(false, false)
  if win then
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_set_current_win(win)
    prepare(win)
  else
    win = open_window(buf, "split")
  end
  if is_alive(old) then
    pcall(vim.fn.jobstop, vim.bo[old.buf].channel)
    vim.api.nvim_buf_delete(old.buf, { force = true })
  end

  -- Same shell as the terminal windows when the Platform Layer provides one;
  -- a string goes through 'shell' + 'shellcmdflag'.
  local exec = require("sinbin.platform").terminal_exec
  local term = { buf = buf, name = opts.name or id, done = false }
  vim.fn.jobstart(exec and exec(cmd) or cmd, {
    term = true,
    cwd = opts.cwd,
    on_exit = function()
      term.done = true
      vim.schedule(function()
        -- In terminal mode the next key would close a finished terminal and lose its
        -- output, so drop back to Normal mode when the command ends.
        if vim.api.nvim_get_current_buf() == buf and vim.api.nvim_get_mode().mode == "t" then
          vim.cmd.stopinsert()
        end
      end)
    end,
  })
  terms[id] = term

  -- Cursor on the last line keeps the window following the output.
  vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  if opts.focus then
    vim.cmd.startinsert()
  elseif prev ~= win and vim.api.nvim_win_is_valid(prev) then
    vim.api.nvim_set_current_win(prev)
  end
end

--- Ends terminal `id` now (its windows show another terminal of the area or close), so
--- the same id can start again right away.
function M.close(id)
  local term = terms[id]
  terms[id] = nil
  if is_alive(term) then
    close_buffer(term.buf)
  end
end

--- Stops the command running in terminal `id`.
--- @return boolean stopped false when nothing was running
function M.stop(id)
  local term = terms[id]
  if not is_alive(term) then
    return false
  end
  local chan = vim.bo[term.buf].channel
  if vim.fn.jobwait({ chan }, 0)[1] ~= -1 then
    return false
  end
  vim.fn.jobstop(chan)
  return true
end

--- Shows terminal `id` in its area if it is hidden, else focuses it.
function M.show(id)
  local term = terms[id]
  if not is_alive(term) then
    return
  end
  local win = find_window(term.buf)
  if win then
    vim.api.nvim_set_current_win(win)
  else
    open_window(term.buf, term.kind == "right" and "right" or "split")
  end
  vim.cmd.startinsert()
end

------------------------------------------------------------------------------
-- Right area full screen (TASK-016): its terminal in a float over the editor area
-- (tab bar and statusline stay), the right column closed meanwhile. Again: back to
-- the column at its width. The float counts as the right area (tabs, guard, toggles).

--- @type { win: integer, width?: integer }?
local zoom

local function zoom_config()
  local top = vim.o.showtabline > 0 and 1 or 0
  local bottom = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
  return { relative = "editor", row = top, col = 0, width = vim.o.columns, height = math.max(1, vim.o.lines - top - bottom), style = "minimal", zindex = 40 }
end

--- @return boolean whether the right area is shown full screen
function M.is_zoomed()
  return zoom ~= nil and vim.api.nvim_win_is_valid(zoom.win)
end

function M.toggle_zoom()
  if M.is_zoomed() then
    local buf, width = vim.api.nvim_win_get_buf(zoom.win), zoom.width
    local float = zoom.win
    zoom = nil
    vim.api.nvim_win_close(float, true)
    local win = open_window(buf, "right")
    if width then
      vim.api.nvim_win_set_width(win, width)
      vim.w[win].sinbin_width = width
    end
    vim.cmd.startinsert()
    return
  end
  local right = layout.right_win()
  local buf = right and vim.api.nvim_win_get_buf(right) or (area_terms("right")[1] or {}).buf
  if not buf then
    vim.notify("오른쪽 영역에 열린 Terminal 없음 (<Space>at Agent Shell, <Space>ac Claude Code)", vim.log.levels.INFO)
    return
  end
  local width = right and (vim.w[right].sinbin_width or vim.api.nvim_win_get_width(right))
  if right then
    vim.api.nvim_win_close(right, true)
  end
  local win = vim.api.nvim_open_win(buf, true, zoom_config())
  layout.mark(win, "right")
  vim.w[win].sinbin_zoom = true
  prepare(win)
  zoom = { win = win, width = width }
  vim.cmd.startinsert()
end

vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("sinbin_zoom", { clear = true }),
  desc = "Keep the full screen right area full screen",
  callback = function()
    if M.is_zoomed() then
      vim.api.nvim_win_set_config(zoom.win, zoom_config())
    end
  end,
})

--- Terminal the bottom panel showed when it was last hidden by toggle_panel().
local last_panel_buf

--- The whole bottom panel, like VS Code Ctrl+`: hidden -> shown again (last shown
--- terminal, else Terminal 1), visible elsewhere -> focused, focused -> hidden.
function M.toggle_panel()
  local panel = layout.panel_win()
  if panel == vim.api.nvim_get_current_win() then
    last_panel_buf = vim.api.nvim_win_get_buf(panel)
    vim.api.nvim_win_close(panel, true)
    return
  end
  if panel then
    vim.api.nvim_set_current_win(panel)
    return
  end
  local items = panel_terms()
  for _, t in ipairs(items) do
    if t.buf == last_panel_buf then
      return M.show(t.id)
    end
  end
  if items[1] then
    return M.show(items[1].id)
  end
  M.toggle("1", "split")
end

--- Whether `buf` is a terminal still waiting for input: a running shell / program,
--- not the finished output of a Run command.
local function wants_input(buf)
  for _, t in pairs(terms) do
    if t.buf == buf and t.done then
      return false
    end
  end
  local chan = vim.bo[buf].channel
  return chan > 0 and vim.fn.jobwait({ chan }, 0)[1] == -1
end

-- Entering a terminal window any way (keys, <C-w>, mouse) goes straight to input
-- (TASK-016). Scheduled: callers may move on to another window right away.
vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("sinbin_terminal", { clear = true }),
  desc = "Terminal mode when entering a terminal",
  callback = function()
    vim.schedule(function()
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].buftype == "terminal" and vim.api.nvim_get_mode().mode == "nt" and wants_input(buf) then
        vim.cmd.startinsert()
      end
    end)
  end,
})

local map = vim.keymap.set
map("n", "<Leader>tt", function() M.toggle(tostring(vim.v.count1), "split") end, { desc = "Terminal (bottom)" })
map("n", "<Leader>tp", M.toggle_panel, { desc = "Bottom panel" })
-- VS Code's Ctrl+` with Alt (TASK-016): Windows Terminal does not send Ctrl+` at all
-- (user check, 2026-10-06), Alt+` arrives like Alt+h/j/k/l.
map({ "n", "t" }, "<M-`>", M.toggle_panel, { desc = "Bottom panel" })
map("n", "<Leader>tf", function() M.toggle("float", "float") end, { desc = "Terminal (float)" })
-- <Esc> is left to the program (Claude Code, lazygit use it); <C-q> leaves terminal mode.
map("t", "<C-q>", [[<C-\><C-n>]], { desc = "Leave terminal mode" })

return M
