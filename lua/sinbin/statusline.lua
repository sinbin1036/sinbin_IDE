-- Statusline content for mini.statusline (TASK-016): one line for the whole screen
-- ('laststatus' = 3), laid out like VS Code's status bar: items with codicons, spaced
-- apart on one background, which turns orange while debugging.
--   left   MODE | branch* | 0↓ 1↑ | errors warnings | working directory
--   right  Run / Debug / Agent badges (only while active) | Ln, Col | filetype

local M = {}

-- Codicons (the icons VS Code uses), part of Nerd Fonts.
local ICON = {
  branch = "\u{ea68}",
  sync = "\u{ea77}",
  publish = "\u{eb40}",
  error = "\u{ea87}",
  warn = "\u{ea6c}",
  folder = "\u{ea83}",
  run = "\u{eb2c}",
  debug = "\u{eaaf}",
  pause = "\u{ead1}",
  agent = "\u{f06a9}",
}

-- Deep, saturated colors with white bold text (user choice: stronger than the
-- colorscheme's pastel mode colors).
local C = {
  white = "#ffffff",
  dark = "#1b1d2b",
  fg = "#c8d3f5",
  bar = "#1e2030", -- statusline background
  debug_bar = "#c2410c", -- whole bar while debugging, like VS Code
  normal = "#1f6feb",
  insert = "#2ea043",
  visual = "#8957e5",
  replace = "#da3633",
  command = "#d29922",
  other = "#1b998b", -- terminal and the rest
  error = "#ff757f",
  warn = "#ffc777",
  run = "#2ea043",
  agent = "#8957e5",
  debug = "#7c2d12", -- badge, darker than the orange bar
}

local function set_hl()
  local hl = vim.api.nvim_set_hl
  for name, bg in pairs({ Normal = C.normal, Insert = C.insert, Visual = C.visual, Replace = C.replace, Other = C.other }) do
    hl(0, "MiniStatuslineMode" .. name, { fg = C.white, bg = bg, bold = true })
  end
  hl(0, "MiniStatuslineModeCommand", { fg = C.dark, bg = C.command, bold = true })
  -- Bar items, normal and debugging ("D") backgrounds.
  for suffix, bg in pairs({ [""] = C.bar, D = C.debug_bar }) do
    local debugging = suffix == "D"
    hl(0, "SinbinStlBar" .. suffix, { fg = debugging and C.white or C.fg, bg = bg })
    hl(0, "SinbinStlStrong" .. suffix, { fg = C.white, bg = bg, bold = true })
    hl(0, "SinbinStlError" .. suffix, { fg = debugging and C.white or C.error, bg = bg, bold = true })
    hl(0, "SinbinStlWarn" .. suffix, { fg = debugging and C.white or C.warn, bg = bg, bold = true })
  end
  hl(0, "SinbinStlRun", { fg = C.white, bg = C.run, bold = true })
  hl(0, "SinbinStlDebug", { fg = C.white, bg = C.debug, bold = true })
  hl(0, "SinbinStlAgent", { fg = C.white, bg = C.agent, bold = true })
end
set_hl()

local group = vim.api.nvim_create_augroup("sinbin_statusline", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", { group = group, desc = "Statusline colors", callback = set_hl })

------------------------------------------------------------------------------
-- Repository state, read asynchronously: pull / push = commits behind / ahead of the
-- upstream branch from the local refs (no fetch: the remote side is as of the last
-- fetch / pull), dirty = uncommitted changes (the `*` after the branch, like VS Code).

--- @class sinbin.RepoState
--- @field behind? integer
--- @field ahead? integer
--- @field upstream? boolean
--- @field dirty? boolean
--- @field head? string branch, for buffers without gitsigns (terminals)
--- @field time? integer
--- @field running? integer commands still running

--- @type table<string, sinbin.RepoState>
local repos = {}

local function git_root()
  local file = vim.api.nvim_buf_get_name(0)
  local source = (vim.bo.buftype == "" and file ~= "") and file or vim.fn.getcwd()
  local root = vim.fs.root(source, ".git")
  return root and vim.fs.normalize(root)
end

--- @param force? boolean skip the 3 second throttle
local function refresh(force)
  local root = git_root()
  if not root or vim.fn.executable("git") == 0 then
    return
  end
  local c = repos[root] or {}
  repos[root] = c
  if (c.running or 0) > 0 or (not force and c.time and vim.uv.now() - c.time < 3000) then
    return
  end
  c.running = 3
  local function done()
    c.running = c.running - 1
    if c.running == 0 then
      c.time = vim.uv.now()
      vim.cmd.redrawstatus()
    end
  end
  vim.system({ "git", "rev-list", "--left-right", "--count", "@{upstream}...HEAD" }, { cwd = root, text = true }, function(r)
    vim.schedule(function()
      local behind, ahead = (r.stdout or ""):match("(%d+)%s+(%d+)")
      c.upstream = r.code == 0 and behind ~= nil
      c.behind, c.ahead = tonumber(behind), tonumber(ahead)
      done()
    end)
  end)
  vim.system({ "git", "branch", "--show-current" }, { cwd = root, text = true }, function(r)
    vim.schedule(function()
      c.head = r.code == 0 and vim.trim(r.stdout or "") or nil
      done()
    end)
  end)
  -- --no-optional-locks: status would take .git/index.lock to refresh the index, and a
  -- Neovim quitting meanwhile kills it, leaving the lock behind (git then refuses to
  -- commit until it is deleted, TASK-023).
  vim.system({ "git", "--no-optional-locks", "status", "--porcelain" }, { cwd = root, text = true }, function(r)
    vim.schedule(function()
      c.dirty = r.code == 0 and (r.stdout or "") ~= ""
      done()
    end)
  end)
end

vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "DirChanged", "BufWritePost", "CursorHold" }, {
  group = group,
  desc = "Statusline repository state",
  callback = function() refresh(false) end,
})
-- Commits, pulls and pushes happen in a terminal (lazygit, shell), `:!git` or outside
-- Neovim: read again right away.
vim.api.nvim_create_autocmd({ "TermClose", "TermLeave", "ShellCmdPost", "FocusGained" }, {
  group = group,
  desc = "Statusline repository state after git in a terminal",
  callback = function() vim.schedule(function() refresh(true) end) end,
})

------------------------------------------------------------------------------

local function esc(text)
  return (text:gsub("%%", "%%%%"))
end

--- Items of the bar, separated by wide gaps. `D` = debugging background suffix.
local function left_items(D)
  local items = {}
  local root = git_root()
  local c = root and repos[root]
  local head = vim.b.gitsigns_head or (c and c.head)
  if head and head ~= "" then
    items[#items + 1] = ("%%#SinbinStlStrong%s#%s %s%s"):format(D, ICON.branch, esc(head), (c and c.dirty) and "*" or "")
    if c and c.upstream then
      items[#items + 1] = ("%%#SinbinStlBar%s#%s %d↓ %d↑"):format(D, ICON.sync, c.behind, c.ahead)
    elseif c and c.upstream == false then
      items[#items + 1] = ("%%#SinbinStlBar%s#%s publish"):format(D, ICON.publish)
    end
  end
  -- Errors / warnings of the current file, always shown like VS Code's problems item.
  if vim.bo.buftype == "" then
    local count = vim.diagnostic.count(0)
    local s = vim.diagnostic.severity
    items[#items + 1] = ("%%#SinbinStlError%s#%s %d  %%#SinbinStlWarn%s#%s %d"):format(
      D, ICON.error, count[s.ERROR] or 0, D, ICON.warn, count[s.WARN] or 0)
  end
  items[#items + 1] = ("%%#SinbinStlBar%s#%s %s"):format(D, ICON.folder, esc(vim.fn.fnamemodify(vim.fn.getcwd(), ":t")))
  return items
end

--- Run / Debug / Agent badges, each only while it is active.
local function badges(session)
  local list = {}
  if require("sinbin.terminal").job_running("run") then
    list[#list + 1] = "%#SinbinStlRun# " .. ICON.run .. " Run "
  end
  if session then
    local label = session.stopped_thread_id and (ICON.pause .. " Debug 정지") or (ICON.debug .. " Debug")
    list[#list + 1] = "%#SinbinStlDebug# " .. label .. " "
  end
  for _, name in ipairs(require("sinbin.agent").running()) do
    list[#list + 1] = "%#SinbinStlAgent# " .. ICON.agent .. " " .. name .. " "
  end
  return list
end

local GAP = "   "

function M.active()
  local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
  local ok, dap = pcall(require, "dap")
  local session = ok and dap.session() or nil
  local D = session and "D" or ""
  local bar = "%#SinbinStlBar" .. D .. "#"

  local right = {}
  for _, b in ipairs(badges(session)) do
    right[#right + 1] = b .. bar
  end
  right[#right + 1] = "Ln %l, Col %v"
  local ft = vim.bo.filetype
  if ft ~= "" then
    right[#right + 1] = MiniIcons.get("filetype", ft) .. " " .. ft
  end

  return table.concat({
    "%#", mode_hl, "# ", mode:upper(), " ",
    bar, GAP, table.concat(left_items(D), bar .. GAP),
    bar, "%<%=",
    table.concat(right, GAP), GAP,
  })
end

return M
