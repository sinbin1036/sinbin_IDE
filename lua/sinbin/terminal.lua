-- Terminal windows (TASK-012), built on jobstart(term = true).
-- Numbered shell terminals in a bottom split, one floating shell terminal, program
-- terminals in a right split (AI Agent CLIs, TASK-015) and one-off command terminals
-- (lazygit). Hiding a terminal keeps its process running.

local M = {}

--- @class sinbin.Term
--- @field buf integer
--- @field name string
--- @field kind? "split"|"float"|"right" where it is shown again

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

--- Opens a window for `buf` and returns its id.
--- @param buf integer
--- @param kind "split"|"float"|"right"
local function open_window(buf, kind)
  local win
  if kind == "float" then
    win = vim.api.nvim_open_win(buf, true, float_config())
  elseif kind == "right" then
    win = vim.api.nvim_open_win(buf, true, {
      split = "right",
      win = -1, -- full height at the right of the tab
      width = math.max(60, math.floor(vim.o.columns * 0.4)),
    })
    vim.wo[win].winfixwidth = true
  else
    win = vim.api.nvim_open_win(buf, true, {
      split = "below",
      win = -1, -- full width at the bottom of the tab
      height = math.max(8, math.floor(vim.o.lines * 0.3)),
    })
    vim.wo[win].winfixheight = true
  end
  -- Set on every window: a re-shown terminal gets a fresh window.
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
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

--- Starts `cmd` in a new terminal buffer shown in a new window.
--- @param cmd string|string[]
--- @param kind "split"|"float"
--- @param on_exit? fun(buf: integer)
--- @param cwd? string
local function start(cmd, kind, on_exit, cwd)
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
  vim.cmd.startinsert()
  return buf
end

--- Closes every window showing `buf` and deletes it.
local function close_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    -- The last window of the editor cannot be closed; switch it to an empty buffer instead.
    if #vim.api.nvim_list_wins() > 1 then
      vim.api.nvim_win_close(win, true)
    else
      vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
    end
  end
  vim.api.nvim_buf_delete(buf, { force = true })
end

--- Shows or hides terminal `id`: a shell, or the program `opts.cmd` (a shell command
--- line, run like Run commands so Windows npm shims work).
--- @param id string
--- @param kind "split"|"float"|"right"
--- @param opts? { cmd?: string, cwd?: string, name?: string }
function M.toggle(id, kind, opts)
  opts = opts or {}
  local term = terms[id]
  if is_alive(term) then
    local win = find_window(term.buf)
    if win then
      vim.api.nvim_win_close(win, true)
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
    -- `exit` in the shell / the program quit: drop the window and buffer.
    terms[id] = nil
    close_buffer(b)
  end, opts.cwd)
  terms[id] = { buf = buf, kind = kind, name = opts.name or (kind == "float" and "float" or ("terminal " .. id)) }
end

--- Whether terminal `id` is running.
function M.is_running(id)
  return is_alive(terms[id])
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
  vim.fn.jobstart(exec and exec(cmd) or cmd, {
    term = true,
    cwd = opts.cwd,
    on_exit = function()
      vim.schedule(function()
        -- In terminal mode the next key would close a finished terminal and lose its
        -- output, so drop back to Normal mode when the command ends.
        if vim.api.nvim_get_current_buf() == buf and vim.api.nvim_get_mode().mode == "t" then
          vim.cmd.stopinsert()
        end
      end)
    end,
  })
  terms[id] = { buf = buf, name = opts.name or id }

  -- Cursor on the last line keeps the window following the output.
  vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  if opts.focus then
    vim.cmd.startinsert()
  elseif prev ~= win and vim.api.nvim_win_is_valid(prev) then
    vim.api.nvim_set_current_win(prev)
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

--- Live shell terminals, for pickers.
--- @return { id: string, name: string, buf: integer }[]
function M.list()
  local items = {}
  for id, term in pairs(terms) do
    if is_alive(term) then
      items[#items + 1] = { id = id, name = term.name, buf = term.buf }
    end
  end
  table.sort(items, function(a, b) return a.id < b.id end)
  return items
end

--- Shows terminal `id` in the bottom split if it is hidden, else focuses it.
function M.show(id)
  local term = terms[id]
  if not is_alive(term) then
    return
  end
  local win = find_window(term.buf)
  if win then
    vim.api.nvim_set_current_win(win)
  else
    open_window(term.buf, "split")
  end
  vim.cmd.startinsert()
end

local map = vim.keymap.set
map("n", "<Leader>tt", function() M.toggle(tostring(vim.v.count1), "split") end, { desc = "Terminal (bottom)" })
map("n", "<Leader>tf", function() M.toggle("float", "float") end, { desc = "Terminal (float)" })
-- <Esc> is left to the program (Claude Code, lazygit use it); <C-q> leaves terminal mode.
map("t", "<C-q>", [[<C-\><C-n>]], { desc = "Leave terminal mode" })

return M
