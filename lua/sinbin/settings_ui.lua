-- Settings panel (TASK-019): a centered floating window listing sinbin.settings by
-- section with their current values. j/k move, <CR>/<Space> or l/h change the value
-- (applied and saved at once), actions run after the panel closes, q/<Esc> close.

local settings = require("sinbin.settings")

local M = {}

local ns = vim.api.nvim_create_namespace("sinbin_settings_ui")
local LABEL_WIDTH = 32

--- @type { buf: integer, win: integer, rows: table<integer, sinbin.Setting> }?
local panel

local function choice_index(setting, value)
  for i, c in ipairs(setting.choices) do
    if c[1] == value then
      return i
    end
  end
  return 1
end

--- Value text and its highlight group.
local function value_text(setting)
  if not setting.choices then
    return "→", "Special"
  end
  local value = settings.get(setting.key)
  if type(setting.default) == "boolean" and setting.choices[1][2] == "켬" then
    return value and "[x]" or "[ ]", value and "DiagnosticOk" or "Comment"
  end
  return "‹ " .. setting.choices[choice_index(setting, value)][2] .. " ›", "Special"
end

local function pad(str, width) return str .. (" "):rep(math.max(1, width - vim.fn.strdisplaywidth(str))) end

--- Lines, highlights and the setting on each item line (1-based line number).
local function build()
  local lines, hls, rows = {}, {}, {}
  local section
  for _, s in ipairs(settings.list) do
    if s.section ~= section then
      if section then
        lines[#lines + 1] = ""
      end
      section = s.section
      lines[#lines + 1] = " " .. section
      hls[#hls + 1] = { #lines, 0, -1, "Title" }
    end
    local value, value_hl = value_text(s)
    local head = "   " .. pad(s.label, LABEL_WIDTH)
    local line = head .. value
    hls[#hls + 1] = { #lines + 1, #head, #line, value_hl }
    if s.note then
      local note = "  (" .. s.note .. ")"
      hls[#hls + 1] = { #lines + 1, #line, #line + #note, "Comment" }
      line = line .. note
    end
    lines[#lines + 1] = line
    rows[#lines] = s
  end
  return lines, hls, rows
end

local function render()
  local lines, hls, rows = build()
  panel.rows = rows
  vim.bo[panel.buf].modifiable = true
  vim.api.nvim_buf_set_lines(panel.buf, 0, -1, false, lines)
  vim.bo[panel.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(panel.buf, ns, 0, -1)
  for _, h in ipairs(hls) do
    vim.api.nvim_buf_set_extmark(panel.buf, ns, h[1] - 1, h[2], {
      end_col = h[3] == -1 and #lines[h[1]] or h[3],
      hl_group = h[4],
    })
  end
  return lines
end

local function current() return panel.rows[vim.api.nvim_win_get_cursor(panel.win)[1]] end

--- Moves to the next / previous item line, wrapping around.
local function move(dir)
  local line = vim.api.nvim_win_get_cursor(panel.win)[1]
  local count = vim.api.nvim_buf_line_count(panel.buf)
  for _ = 1, count do
    line = (line - 1 + dir) % count + 1
    if panel.rows[line] then
      vim.api.nvim_win_set_cursor(panel.win, { line, 0 })
      return
    end
  end
end

function M.close()
  if panel and vim.api.nvim_win_is_valid(panel.win) then
    vim.api.nvim_win_close(panel.win, true)
  end
  panel = nil
end

local function step(dir)
  local s = current()
  if not s or not s.choices then
    return
  end
  local i = (choice_index(s, settings.get(s.key)) - 1 + dir) % #s.choices + 1
  settings.set(s.key, s.choices[i][1])
  -- Applying a theme can redraw everything; the panel may be gone.
  if panel and vim.api.nvim_buf_is_valid(panel.buf) then
    render()
  end
end

local function activate()
  local s = current()
  if not s then
    return
  end
  if s.choices then
    step(1)
    return
  end
  M.close()
  vim.schedule(function()
    s.run()
    -- Reset asks first and changes every value: show the result.
    if s.key == "reset" then
      M.open()
    end
  end)
end

function M.open()
  if panel and vim.api.nvim_win_is_valid(panel.win) then
    vim.api.nvim_set_current_win(panel.win)
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "sinbinsettings"
  -- mini.clue's buffer triggers (<Space> = Leader) would take <Space> here.
  vim.b[buf].miniclue_disable = true
  panel = { buf = buf, rows = {} }
  local lines = render()

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width + 2, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 6)
  panel.win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = "rounded",
    title = " SinBin 설정 ",
    title_pos = "center",
    footer = " <CR>/Space 바꾸기 · h/l 값 · q 닫기 ",
    footer_pos = "center",
  })
  -- [0]: like :setlocal, the global values stay (plain vim.wo[win] is like :set).
  local wo = vim.wo[panel.win][0]
  wo.cursorline = true
  wo.wrap = false
  wo.list = false
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  move(1)

  local function map(keys, fn)
    for _, key in ipairs(keys) do
      vim.keymap.set("n", key, fn, { buffer = buf, nowait = true })
    end
  end
  map({ "j", "<Down>" }, function() move(1) end)
  map({ "k", "<Up>" }, function() move(-1) end)
  map({ "<CR>", "<Space>" }, activate)
  map({ "l", "<Right>" }, function() step(1) end)
  map({ "h", "<Left>" }, function() step(-1) end)
  map({ "q", "<Esc>" }, M.close)

  local win = panel.win
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    desc = "Close the settings panel",
    callback = function()
      -- Only this panel: a new one may be open by the time this runs.
      vim.schedule(function()
        if panel and panel.win == win then
          M.close()
        end
      end)
    end,
  })
end

return M
