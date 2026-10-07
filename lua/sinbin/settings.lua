-- User settings (TASK-019): the list of settings with defaults, the values changed from
-- them in stdpath("data")/sinbin/settings.json, and how to apply each one right away.
-- Modules read values with get(); the panel (sinbin/settings_ui.lua) changes them with
-- set(). Loaded before options.lua, so nothing here requires a plugin at load time.

local M = {}

M.file = vim.fn.stdpath("data") .. "/sinbin/settings.json"

local function bool_choices() return { { true, "켬" }, { false, "끔" } } end

-- Window options of code windows (not terminals, panels, floats).
local function set_win_option(names, value)
  for _, name in ipairs(names) do
    vim.go[name] = value
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "" and vim.api.nvim_win_get_config(win).relative == "" then
      for _, name in ipairs(names) do
        vim.wo[win][name] = value
      end
    end
  end
end

local function win_option(...)
  local names = { ... }
  return function(value) set_win_option(names, value) end
end

local function refresh_starter() require("sinbin.starter").refresh() end

--- @class sinbin.Setting
--- @field key string
--- @field section string
--- @field label string
--- @field default any
--- @field choices? { [1]: any, [2]: string }[] values and labels; nil for an action
--- @field apply? fun(value: any) applies a changed value now
--- @field note? string when the change takes effect, if not right away
--- @field run? fun() for an action

--- In panel order.
--- @type sinbin.Setting[]
M.list = {
  {
    key = "theme",
    section = "화면",
    label = "색 테마",
    default = "moon",
    choices = { { "moon", "moon" }, { "storm", "storm" }, { "night", "night" } },
    apply = function() M.apply_theme() end,
  },
  {
    key = "transparent",
    section = "화면",
    label = "배경 투명",
    default = false,
    choices = bool_choices(),
    apply = function() M.apply_theme() end,
  },
  {
    key = "relativenumber",
    section = "화면",
    label = "상대 줄 번호",
    default = true,
    choices = bool_choices(),
    apply = win_option("relativenumber"),
  },
  {
    key = "cursorline",
    section = "화면",
    label = "현재 줄 강조",
    default = true,
    choices = bool_choices(),
    apply = win_option("cursorline"),
  },
  {
    key = "list",
    section = "화면",
    label = "공백 문자 표시",
    default = true,
    choices = bool_choices(),
    apply = win_option("list"),
  },
  {
    key = "wrap",
    section = "화면",
    label = "긴 줄 줄바꿈",
    default = true,
    choices = bool_choices(),
    apply = win_option("wrap"),
  },

  {
    key = "indent",
    section = "편집",
    label = "들여쓰기 폭",
    default = 4,
    choices = { { 2, "2" }, { 4, "4" }, { 8, "8" } },
    note = "새 파일부터",
    apply = function(value)
      vim.go.shiftwidth = value
      vim.go.tabstop = value
      vim.go.softtabstop = value
    end,
  },
  {
    key = "expandtab",
    section = "편집",
    label = "들여쓰기 문자",
    default = true,
    choices = { { true, "Spaces" }, { false, "Tab" } },
    note = "새 파일부터",
    apply = function(value) vim.go.expandtab = value end,
  },
  {
    key = "search_case",
    section = "편집",
    label = "검색 대소문자",
    default = "smart",
    choices = { { "smart", "대문자 있으면 구분" }, { "ignore", "항상 무시" }, { "match", "항상 구분" } },
    apply = function(value)
      vim.o.ignorecase = value ~= "match"
      vim.o.smartcase = value == "smart"
    end,
  },
  {
    key = "scrolloff",
    section = "편집",
    label = "커서 위아래 여백",
    default = 8,
    choices = { { 0, "0" }, { 4, "4" }, { 8, "8" }, { 15, "15" }, { 999, "가운데 고정" } },
    apply = function(value) vim.o.scrolloff = value end,
  },
  {
    key = "autosave",
    section = "편집",
    label = "자동 저장",
    default = false,
    choices = bool_choices(),
  },

  {
    key = "startup_terminal",
    section = "IDE",
    label = "시작 시 Terminal",
    default = true,
    choices = bool_choices(),
    note = "재시작",
  },
  {
    key = "startup_agent",
    section = "IDE",
    label = "시작 시 Agent",
    default = false,
    choices = bool_choices(),
    note = "재시작",
  },
  {
    key = "blame",
    section = "IDE",
    label = "줄 끝 Git blame",
    default = true,
    choices = bool_choices(),
    apply = function(value) require("gitsigns").toggle_current_line_blame(value) end,
  },
  {
    key = "diagnostics",
    section = "IDE",
    label = "에러·경고 표시",
    default = true,
    choices = bool_choices(),
    apply = function(value) vim.diagnostic.enable(value) end,
  },
  {
    key = "ime",
    section = "IDE",
    label = "한/영 자동 전환",
    default = true,
    choices = bool_choices(),
  },
  {
    key = "outline_autojump",
    section = "IDE",
    label = "Outline 이동 시 코드 따라가기",
    default = false,
    choices = bool_choices(),
    note = "Outline 다시 열 때",
    apply = function(value) require("aerial.config").autojump = value end,
  },

  {
    key = "starter",
    section = "시작 화면",
    label = "시작 화면 사용",
    default = true,
    choices = bool_choices(),
    note = "재시작",
  },
  {
    key = "starter_gradient",
    section = "시작 화면",
    label = "로고 gradient",
    default = true,
    choices = bool_choices(),
    apply = function()
      require("sinbin.starter").set_hl()
      refresh_starter()
    end,
  },
  {
    key = "starter_tip",
    section = "시작 화면",
    label = "Tip 표시",
    default = true,
    choices = bool_choices(),
    apply = refresh_starter,
  },
  {
    key = "starter_projects",
    section = "시작 화면",
    label = "최근 프로젝트 개수",
    default = 5,
    choices = { { 0, "0" }, { 1, "1" }, { 2, "2" }, { 3, "3" }, { 4, "4" }, { 5, "5" } },
    apply = refresh_starter,
  },

  {
    key = "agent_default",
    section = "Agent",
    label = "기본 Agent",
    default = "claude",
    choices = { { "claude", "Claude Code" }, { "codex", "Codex" } },
    apply = function(value) require("sinbin.agent").set_default(value) end,
  },
  {
    key = "agent_width",
    section = "Agent",
    label = "패널 폭 (화면 대비)",
    default = 40,
    choices = { { 30, "30%" }, { 40, "40%" }, { 50, "50%" } },
    apply = function() require("sinbin.layout").resize_right() end,
  },
  {
    key = "agent_resume",
    section = "Agent",
    label = "이전 대화 이어서 시작",
    default = false,
    choices = bool_choices(),
    note = "다음 Agent 시작부터",
  },

  {
    key = "open_file",
    section = "고급",
    label = "설정 파일 열기 (settings.json)",
    run = function() M.edit_file() end,
  },
  {
    key = "health_pack",
    section = "고급",
    label = "Plugin 상태",
    run = function() vim.cmd("checkhealth vim.pack") end,
  },
  {
    key = "health_lsp",
    section = "고급",
    label = "LSP 상태",
    run = function() vim.cmd("checkhealth vim.lsp") end,
  },
  {
    key = "health_treesitter",
    section = "고급",
    label = "Treesitter 상태",
    run = function() vim.cmd("checkhealth nvim-treesitter") end,
  },
  {
    key = "reset",
    section = "고급",
    label = "설정 초기화",
    run = function()
      if vim.fn.confirm("설정을 모두 기본값으로 되돌릴까요?", "&예\n&아니오", 2) == 1 then
        M.reset()
      end
    end,
  },
}

--- @type table<string, sinbin.Setting>
local by_key = {}
for _, s in ipairs(M.list) do
  by_key[s.key] = s
end

local function valid(setting, value)
  for _, c in ipairs(setting.choices or {}) do
    if c[1] == value then
      return true
    end
  end
  return false
end

--- Changed values from settings.json. Unknown keys and invalid values are dropped.
--- @type table<string, any>
local values = {}

local function load()
  values = {}
  local ok, lines = pcall(vim.fn.readfile, M.file)
  if not ok or #lines == 0 then
    return
  end
  local decoded_ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded_ok or type(data) ~= "table" then
    vim.notify("settings.json을 읽을 수 없어 기본값을 씁니다", vim.log.levels.WARN)
    return
  end
  for key, value in pairs(data) do
    local setting = by_key[key]
    if setting and valid(setting, value) and value ~= setting.default then
      values[key] = value
    end
  end
end

--- Writes only the values that differ from the defaults, one per line in panel order.
local function save()
  local lines = {}
  for _, s in ipairs(M.list) do
    if values[s.key] ~= nil then
      lines[#lines + 1] = ("  %s: %s"):format(vim.json.encode(s.key), vim.json.encode(values[s.key]))
    end
  end
  for i = 1, #lines - 1 do
    lines[i] = lines[i] .. ","
  end
  table.insert(lines, 1, "{")
  lines[#lines + 1] = "}"
  vim.fn.mkdir(vim.fs.dirname(M.file), "p")
  vim.fn.writefile(lines, M.file)
end

--- @param key string
function M.get(key)
  local value = values[key]
  if value == nil then
    return by_key[key].default
  end
  return value
end

--- Saves `value` and applies it now (if the setting can be applied without a restart).
--- @param key string
function M.set(key, value)
  local setting = by_key[key]
  if value == setting.default then
    values[key] = nil
  else
    values[key] = value
  end
  save()
  M.apply(key)
end

--- @param key string
function M.apply(key)
  local setting = by_key[key]
  if setting.apply then
    local ok, err = pcall(setting.apply, M.get(key))
    if not ok then
      vim.notify(("설정 적용 실패 (%s): %s"):format(setting.label, err), vim.log.levels.ERROR)
    end
  end
end

local function apply_all()
  for _, s in ipairs(M.list) do
    if s.apply then
      M.apply(s.key)
    end
  end
end

function M.reset()
  values = {}
  os.remove(M.file)
  apply_all()
  vim.notify("설정을 기본값으로 되돌렸습니다")
end

--- Color scheme with the theme and transparency settings.
function M.apply_theme()
  require("tokyonight").setup({ style = M.get("theme"), transparent = M.get("transparent") })
  vim.cmd.colorscheme("tokyonight")
end

--- Opens settings.json (created with the current values); saving it reloads the settings.
function M.edit_file()
  if vim.fn.filereadable(M.file) == 0 then
    save()
  end
  vim.cmd.edit(vim.fn.fnameescape(M.file))
end

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("sinbin_settings", { clear = true }),
  pattern = vim.fs.normalize(M.file),
  desc = "Reload settings.json",
  callback = function()
    load()
    apply_all()
    vim.notify("settings.json 적용")
  end,
})

load()

return M
