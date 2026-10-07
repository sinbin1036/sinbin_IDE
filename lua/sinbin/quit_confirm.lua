-- Forced quit asks first (TASK-022): typing :q!, :qa!, :wq!, :x!, :cq ... on the command
-- line, or ZQ, shows a centered 예/아니오 dialog and runs the command only on 예.
-- Neovim cannot cancel a quit from QuitPre, so the command line <CR> is intercepted
-- instead. Commands run from scripts and plugins (vim.cmd) are not affected.

local M = {}

-- Every abbreviation of the quit commands (":h :quit" etc.).
local quit_names = {}
local function add(full, min)
  for n = min, #full do
    quit_names[full:sub(1, n)] = true
  end
end
add("quit", 1) -- :q[uit]
add("qall", 2) -- :qa[ll]
add("quitall", 5) -- :quita[ll]
add("wq", 2) -- :wq
add("wqall", 3) -- :wqa[ll]
add("xit", 1) -- :x[it]
add("exit", 3) -- :exi[t]
add("xall", 2) -- :xa[ll]

-- :cq[uit] always quits without saving, with or without !.
local cquit_names = {}
for n = 2, 5 do
  cquit_names[("cquit"):sub(1, n)] = true
end

--- @param line string command line text
--- @return boolean
function M.is_forced_quit(line)
  line = line:gsub("^[%s:]+", "")
  local name, bang, rest = line:match("^(%a+)(!?)(.*)$")
  if not name or (rest ~= "" and not rest:match("^[%s%d]")) then
    return false
  end
  if cquit_names[name] then
    return true
  end
  return bang == "!" and quit_names[name] == true
end

local function run(cmd)
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    vim.api.nvim_echo({ { tostring(err):gsub("^Vim:", ""), "ErrorMsg" } }, true, {})
  end
end

local ns = vim.api.nvim_create_namespace("sinbin_quit_confirm")
local WIDTH = 44
local BUTTONS = { "  예 (y)  ", "  아니오 (n)  " }
local dialog -- { win, buf, origin, cmd, choice, button_line, button_cols }

--- @param text string
--- @return string text centered in WIDTH display cells
local function center(text)
  local pad = math.max(0, math.floor((WIDTH - vim.fn.strdisplaywidth(text)) / 2))
  return (" "):rep(pad) .. text
end

local function render()
  local d = dialog
  vim.api.nvim_buf_clear_namespace(d.buf, ns, 0, -1)
  vim.api.nvim_buf_set_extmark(d.buf, ns, 1, 0, { end_col = #d.lines[2], hl_group = "WarningMsg" })
  for i, col in ipairs(d.button_cols) do
    vim.api.nvim_buf_set_extmark(d.buf, ns, d.button_line - 1, col[1], {
      end_col = col[2],
      hl_group = i == d.choice and (i == 1 and "DiffDelete" or "PmenuSel") or "Pmenu",
    })
  end
  vim.api.nvim_win_set_cursor(d.win, { d.button_line, d.button_cols[d.choice][1] })
end

--- @param yes boolean
local function finish(yes)
  local d = dialog
  if not d then
    return
  end
  dialog = nil
  if vim.api.nvim_win_is_valid(d.win) then
    vim.api.nvim_win_close(d.win, true)
  end
  if not yes then
    return
  end
  -- The command applies to the window it was typed in.
  if vim.api.nvim_win_is_valid(d.origin) then
    vim.api.nvim_set_current_win(d.origin)
  end
  run(d.cmd)
end

--- Centered 예/아니오 dialog; runs cmd only on 예. Enter on open = 아니오.
--- @param label string what was typed, shown in the dialog
--- @param cmd string Ex command to run
local function ask(label, cmd)
  if dialog then
    return
  end
  local modified = 0
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted and vim.bo[b].modified then
      modified = modified + 1
    end
  end
  local buttons = BUTTONS[1] .. "   " .. BUTTONS[2]
  local lines = {
    "",
    center(label),
    "",
    center(modified > 0 and ("저장 안 된 파일 %d개의 변경이 사라집니다"):format(modified)
      or "저장 안 된 파일 없음"),
    "",
    center(buttons),
    "",
  }
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.b[buf].miniclue_disable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local first = #lines[6] - #buttons
  local second = first + #BUTTONS[1] + 3
  dialog = {
    buf = buf,
    origin = vim.api.nvim_get_current_win(),
    cmd = cmd,
    choice = 2,
    lines = lines,
    button_line = 6,
    button_cols = { { first, first + #BUTTONS[1] }, { second, second + #BUTTONS[2] } },
  }
  local height = #lines
  dialog.win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - WIDTH) / 2),
    width = WIDTH,
    height = height,
    border = "rounded",
    title = " 강제 종료 ",
    title_pos = "center",
    footer = " y 예 · n/Esc 아니오 · ←/→ 선택 ",
    footer_pos = "center",
    zindex = 250,
  })
  local wo = vim.wo[dialog.win][0]
  wo.cursorline = false
  wo.wrap = false
  wo.list = false
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  render()

  local function map(keys, fn)
    for _, key in ipairs(keys) do
      vim.keymap.set("n", key, fn, { buffer = buf, nowait = true })
    end
  end
  local function select(i)
    dialog.choice = i
    render()
  end
  -- Hotkeys y / n, not 예 / 아니오: those would need the Korean input mode.
  map({ "y", "Y" }, function() finish(true) end)
  map({ "n", "N", "q", "<Esc>" }, function() finish(false) end)
  map({ "<CR>", "<Space>" }, function() finish(dialog.choice == 1) end)
  map({ "h", "<Left>" }, function() select(1) end)
  map({ "l", "<Right>" }, function() select(2) end)
  map({ "<Tab>", "<S-Tab>" }, function() select(3 - dialog.choice) end)

  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    desc = "Leaving the forced quit dialog cancels it",
    callback = function() vim.schedule(function() finish(false) end) end,
  })
end

-- <CR> on the : command line: a forced quit leaves the command line (<C-c>) and asks.
local function on_enter()
  if vim.fn.getcmdtype() ~= ":" then
    return "<CR>"
  end
  local line = vim.fn.getcmdline()
  if not M.is_forced_quit(line) then
    return "<CR>"
  end
  vim.fn.histadd("cmd", line)
  vim.schedule(function() ask(":" .. vim.trim(line), line) end)
  return "<C-c>"
end

for _, key in ipairs({ "<CR>", "<kEnter>", "<NL>" }) do
  vim.keymap.set("c", key, on_enter, { expr = true, desc = "Confirm forced quit" })
end

vim.keymap.set("n", "ZQ", function() ask("ZQ  (:q!)", "q!") end, { desc = "Quit without saving (confirm)" })

return M
