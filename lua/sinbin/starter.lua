-- Start screen (TASK-018): SINBIN logo with a left-to-right gradient, actions in two
-- columns, recent projects (sinbin/projects.lua), plugin count / startup time and a tip.
-- mini.starter makes the items and the query keys; the layout is one content hook.
local projects = require("sinbin.projects")
local settings = require("sinbin.settings")

local M = {}

-- Block letters from the busy.js banner.
local GLYPHS = {
  S = { "███████╗", "██╔════╝", "███████╗", "╚════██║", "███████║", "╚══════╝" },
  I = { "██╗", "██║", "██║", "██║", "██║", "╚═╝" },
  N = { "███╗   ██╗", "████╗  ██║", "██╔██╗ ██║", "██║╚██╗██║", "██║ ╚████║", "╚═╝  ╚═══╝" },
  B = { "██████╗ ", "██╔══██╗", "██████╔╝", "██╔══██╗", "██████╔╝", "╚═════╝ " },
}
local LOGO = {}
for row = 1, 6 do
  LOGO[row] = table.concat(vim.tbl_map(function(ch) return GLYPHS[ch][row] end, vim.fn.split("SINBIN", [[\zs]])))
end
local LOGO_WIDTH = vim.fn.strdisplaywidth(LOGO[1])

-- tokyonight moon blue → magenta → magenta2 (user choice: blue, purple, pink).
local STOPS = { { 0x82, 0xaa, 0xff }, { 0xc0, 0x99, 0xff }, { 0xff, 0x00, 0x7c } }

local function color_at(t)
  local s = t * (#STOPS - 1)
  local i = math.min(math.floor(s), #STOPS - 2) + 1
  local f = s - (i - 1)
  local rgb = {}
  for k = 1, 3 do
    rgb[k] = math.floor(STOPS[i][k] + (STOPS[i + 1][k] - STOPS[i][k]) * f + 0.5)
  end
  return ("#%02x%02x%02x"):format(rgb[1], rgb[2], rgb[3])
end

-- One highlight group per logo column; a shorter text uses evenly spaced ones. With the
-- gradient off (settings panel) all columns take the header color.
function M.set_hl()
  local gradient = settings.get("starter_gradient")
  for col = 1, LOGO_WIDTH do
    local hl = gradient and { fg = color_at((col - 1) / (LOGO_WIDTH - 1)), bold = true }
      or { link = "MiniStarterHeader" }
    vim.api.nvim_set_hl(0, "SinbinStarterLogo" .. col, hl)
  end
  vim.api.nvim_set_hl(0, "SinbinStarterSub", { link = "Comment" })
end
M.set_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("sinbin_starter", { clear = true }),
  desc = "Start screen logo colors",
  callback = M.set_hl,
})

local TIPS = {
  "<Space>sc  명령 팔레트",
  "<Space>sk  Keymap 검색",
  "<Space>fr  최근 파일",
  "Ctrl+P  파일 찾기 (<Space>ff)",
  "Ctrl+B  왼쪽 영역 열기 / 닫기",
  "Alt+a  코드 창 ↔ 오른쪽 영역",
  "Alt+z  오른쪽 영역 전체 화면",
  "Alt+`  하단 패널 열기 / 숨기기",
  "Alt+h/j/k/l  창 이동",
  "]d / [d  다음 / 이전 에러",
  "]h / [h  다음 / 이전 변경 묶음",
  "<Space>gv  전체 변경 검토",
  "<Space>gg  lazygit",
  "<Space>rr  현재 파일 실행",
  "<Space>co  Outline (현재 파일 구조)",
  "<Space>af  현재 파일을 Agent 입력창에",
  "<Space> 누르고 기다리면 키 목록",
  "ys / ds / cs  감싸는 문자 추가 / 삭제 / 교체",
}
-- Picked once per session: a resize refresh keeps the same tip.
local tip = TIPS[vim.uv.hrtime() % #TIPS + 1]

local startup_ms
local function info()
  startup_ms = startup_ms or math.floor((vim.uv.hrtime() - vim.g.sinbin_start) / 1e6 + 0.5)
  return ("%d plugins · %dms"):format(#vim.pack.get(nil, { info = false }), startup_ms)
end

--- Runs what the keymap `lhs` does, so the start screen keeps no copy of it.
local function keymap(lhs)
  return function()
    local map = vim.fn.maparg(lhs, "n", false, true)
    if map.callback then
      map.callback()
    elseif map.rhs then
      vim.api.nvim_feedkeys(vim.keycode(map.rhs), "m", false)
    end
  end
end

local ACTIONS = {
  { "f", "파일 찾기", keymap("<Leader>ff") },
  { "g", "내용 검색", keymap("<Leader>sg") },
  { "e", "파일 탐색기", keymap("<Leader>fe") },
  {
    "c",
    "설정 열기",
    function() require("sinbin.settings_ui").open() end,
  },
  { "q", "종료", "qall" },
}

-- Item names start with their key: typing it leaves one item, which runs.
local function items()
  local list = {}
  for _, a in ipairs(ACTIONS) do
    list[#list + 1] = { name = a[1] .. "  " .. a[2], action = a[3], section = "Actions" }
  end
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  for _, dir in ipairs(projects.list()) do
    if #list - #ACTIONS >= settings.get("starter_projects") then
      break
    end
    if dir ~= cwd then
      list[#list + 1] = {
        name = ("%d  %s"):format(#list - #ACTIONS + 1, (vim.fn.fnamemodify(dir, ":~"):gsub("\\", "/"))),
        action = function() vim.fn.chdir(dir) end,
        section = "Recent Projects",
      }
    end
  end
  return list
end

local function unit(str, type, hl) return { string = str, type = type, hl = hl } end

-- Keeps the start (item key) and the end (project folder) of a long name.
local function truncate(str, width)
  if vim.fn.strdisplaywidth(str) <= width then
    return str
  end
  local head = vim.fn.strcharpart(str, 0, 3) .. "…"
  local chars = vim.fn.split(vim.fn.strcharpart(str, 3), [[\zs]])
  local tail = {}
  local room = width - vim.fn.strdisplaywidth(head)
  for i = #chars, 1, -1 do
    room = room - vim.fn.strdisplaywidth(chars[i])
    if room < 0 then
      break
    end
    table.insert(tail, 1, chars[i])
  end
  return head .. table.concat(tail)
end

-- Character units colored by position, spread over the whole logo gradient.
local function gradient(str)
  local chars = vim.fn.split(str, [[\zs]])
  local units = {}
  for i, ch in ipairs(chars) do
    local col = #chars == 1 and 1 or math.floor((i - 1) / (#chars - 1) * (LOGO_WIDTH - 1) + 0.5) + 1
    units[i] = unit(ch, "header", ch ~= " " and ("SinbinStarterLogo" .. col) or nil)
  end
  return units
end

local INDENT = "  "
local COLUMN_GAP = 4

-- Content hook: replaces mini.starter's layout (header, items, footer are empty or
-- collected here). Lines are either centered or left-aligned at the logo's left edge;
-- the aligning hook after this centers the whole block in the window.
local function layout(content, buf_id)
  local actions, recent = {}, {}
  for _, line in ipairs(content) do
    for _, u in ipairs(line) do
      if u.type == "item" then
        table.insert(u.item.section == "Actions" and actions or recent, u)
      end
    end
  end

  local rows = {}
  local function add(units, center) rows[#rows + 1] = { units = units, center = center } end
  local function blank() add({ unit("", "empty") }) end

  local win = vim.fn.bufwinid(buf_id)
  local win_width = win > 0 and vim.api.nvim_win_get_width(win) or vim.o.columns
  local wide = win_width >= LOGO_WIDTH + 4
  if wide then
    for _, row in ipairs(LOGO) do
      add(gradient(row), true)
    end
    add({ unit("I D E", "header", "SinbinStarterSub") }, true)
  else
    add(gradient("SinBin IDE"), true)
  end

  blank()
  add({ unit("Actions", "section", "MiniStarterSection") })
  local left_width = 0
  for i = 1, #actions, 2 do
    left_width = math.max(left_width, vim.fn.strdisplaywidth(actions[i].string))
  end
  for i = 1, #actions, 2 do
    local line = { unit(INDENT .. INDENT, "empty"), actions[i] }
    if actions[i + 1] then
      local pad = left_width - vim.fn.strdisplaywidth(actions[i].string) + COLUMN_GAP
      vim.list_extend(line, { unit((" "):rep(pad), "empty"), actions[i + 1] })
    end
    add(line)
  end

  if #recent > 0 then
    blank()
    add({ unit("Recent Projects", "section", "MiniStarterSection") })
    -- Paths stay within the logo width (or the window): mini.starter takes the item
    -- name from this string.
    local max = math.min(LOGO_WIDTH, win_width - 2) - #INDENT * 2
    for _, u in ipairs(recent) do
      u.string = truncate(u.string, math.max(max, 12))
      add({ unit(INDENT .. INDENT, "empty"), u })
    end
  end

  blank()
  add({ unit(info(), "footer", "MiniStarterFooter") }, true)
  if settings.get("starter_tip") then
    add({ unit("Tip: " .. tip, "footer", "MiniStarterFooter") }, true)
  end

  local function width(units)
    return vim.fn.strdisplaywidth(table.concat(vim.tbl_map(function(u) return u.string end, units)))
  end
  local block, max_left = 0, 0
  for _, r in ipairs(rows) do
    r.width = width(r.units)
    block = math.max(block, r.width)
    if not r.center then
      max_left = math.max(max_left, r.width)
    end
  end
  local left_edge = wide and math.max(0, math.min(math.floor((block - LOGO_WIDTH) / 2), block - max_left)) or 0

  local result = {}
  for _, r in ipairs(rows) do
    local pad = r.center and math.floor((block - r.width) / 2) or left_edge
    if pad > 0 then
      table.insert(r.units, 1, unit((" "):rep(pad), "empty"))
    end
    result[#result + 1] = r.units
  end
  return result
end

--- Redraws the start screen if it is shown (settings, directory changes).
function M.refresh()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].filetype == "ministarter" and vim.fn.bufwinid(buf) > 0 then
      MiniStarter.refresh(buf)
    end
  end
end

function M.setup()
  local starter = require("mini.starter")
  starter.setup({
    -- Off in the settings panel: an empty buffer as in plain Neovim.
    autoopen = settings.get("starter"),
    evaluate_single = true,
    items = { items },
    header = "",
    footer = "",
    content_hooks = { layout, starter.gen_hook.aligning("center", "center") },
  })

  -- A project picked here (or a directory change elsewhere) updates the list.
  vim.api.nvim_create_autocmd("DirChanged", {
    group = vim.api.nvim_create_augroup("sinbin_starter_refresh", { clear = true }),
    pattern = "global",
    desc = "Refresh the start screen",
    callback = M.refresh,
  })
end

return M
