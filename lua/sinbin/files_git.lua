-- Git status in the mini.files explorer (TASK-016), like VS Code's explorer:
-- the entry name is colored and a letter shown at the right edge.
--   M modified, A added, U untracked, R renamed, ! conflict
-- Folders containing changes take the strongest child's color with a dot.
-- `git status` runs asynchronously, cached briefly per repository.

local M = {}

local ns = vim.api.nvim_create_namespace("sinbin_files_git")

-- Strongest first: a folder shows the highest-ranked status found inside it.
-- hl: name color, letter: the right edge letter (same color, bold).
local STATUS = {
  conflict = { letter = "!", hl = "SinbinFilesGitConflict", rank = 4 },
  modified = { letter = "M", hl = "SinbinFilesGitModified", rank = 3 },
  renamed = { letter = "R", hl = "SinbinFilesGitModified", rank = 3 },
  added = { letter = "A", hl = "SinbinFilesGitAdded", rank = 2 },
  untracked = { letter = "U", hl = "SinbinFilesGitAdded", rank = 1 },
}

--- VS Code-like colors taken from the colorscheme: modified yellow, added/untracked
--- green, conflict red. Bright on purpose: they must stand out from plain names.
local COLOR_FROM = {
  SinbinFilesGitModified = "DiagnosticWarn",
  SinbinFilesGitAdded = "String",
  SinbinFilesGitConflict = "GitSignsDelete",
}

local function set_hl()
  for name, from in pairs(COLOR_FROM) do
    local fg = vim.api.nvim_get_hl(0, { name = from, link = false }).fg
    vim.api.nvim_set_hl(0, name, { fg = fg })
    vim.api.nvim_set_hl(0, name .. "Letter", { fg = fg, bold = true })
  end
end
set_hl()

--- Porcelain XY code -> STATUS key.
local function classify(xy)
  if xy == "??" then
    return "untracked"
  end
  if xy:find("U") or xy == "AA" or xy == "DD" then
    return "conflict"
  end
  if xy:find("R") then
    return "renamed"
  end
  if xy:find("M") or xy:find("T") then
    return "modified"
  end
  if xy:find("A") then
    return "added"
  end
end

--- @class sinbin.GitCache
--- @field time integer
--- @field files table<string, string> absolute path -> STATUS key
--- @field dirs table<string, string> folders containing changes -> STATUS key
--- @field untracked_dirs table<string, true>

--- @type table<string, sinbin.GitCache>
local cache = {}
--- Buffers waiting for a running `git status`, per repository root.
--- @type table<string, integer[]>
local waiting = {}

local TTL_MS = 1000

local function stronger(a, b)
  return (not a or STATUS[b].rank > STATUS[a].rank) and b or a
end

--- Parses `git status --porcelain=v1 -z` output relative to `root`.
local function parse(root, out)
  local c = { time = vim.uv.now(), files = {}, dirs = {}, untracked_dirs = {} }
  local fields = vim.split(out, "\0", { plain = true, trimempty = true })
  local i = 1
  while i <= #fields do
    local f = fields[i]
    local xy, rel = f:sub(1, 2), f:sub(4)
    if xy:find("[RC]") then
      i = i + 1 -- next field is the original path
    end
    local kind = classify(xy)
    if kind then
      local path = root .. "/" .. rel:gsub("/$", "")
      if xy == "??" and rel:sub(-1) == "/" then
        c.untracked_dirs[path] = true
      end
      c.files[path] = kind
      local dir = vim.fs.dirname(path)
      while #dir > #root do
        c.dirs[dir] = stronger(c.dirs[dir], kind)
        dir = vim.fs.dirname(dir)
      end
    end
    i = i + 1
  end
  return c
end

--- Status of `path`: its own, inside an untracked folder, or as a folder with changes.
--- @return string? key, boolean? is_dir_summary
local function lookup(c, root, path)
  if c.files[path] then
    return c.files[path]
  end
  local dir = vim.fs.dirname(path)
  while #dir > #root do
    if c.untracked_dirs[dir] then
      return "untracked"
    end
    dir = vim.fs.dirname(dir)
  end
  if c.dirs[path] then
    return c.dirs[path], true
  end
end

local function decorate(buf, root)
  local c = cache[root]
  if not c or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, l in ipairs(lines) do
    local ok, entry = pcall(MiniFiles.get_fs_entry, buf, i)
    local name_start = l:match("^/%d+/.-/()")
    if ok and entry and name_start then
      local key, summary = lookup(c, root, vim.fs.normalize(entry.path))
      if key then
        local s = STATUS[key]
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, name_start - 1, {
          end_col = #l,
          hl_group = s.hl,
          -- Above mini.files' own name highlight (default extmark priority 4096).
          priority = 4200,
          right_gravity = false,
          virt_text = { { summary and "•" or s.letter, s.hl .. "Letter" } },
          virt_text_pos = "right_align",
        })
      end
    end
  end
end

--- Decorates mini.files buffer `buf` showing directory `dir`.
function M.update(buf, dir)
  local root = vim.fs.root(dir, ".git")
  if not root or vim.fn.executable("git") == 0 then
    return
  end
  root = vim.fs.normalize(root)
  local c = cache[root]
  if c and vim.uv.now() - c.time < TTL_MS then
    decorate(buf, root)
    return
  end
  if waiting[root] then
    table.insert(waiting[root], buf)
    return
  end
  waiting[root] = { buf }
  vim.system({ "git", "status", "--porcelain=v1", "-z" }, { cwd = root, text = true }, function(r)
    vim.schedule(function()
      local bufs = waiting[root]
      waiting[root] = nil
      if r.code ~= 0 then
        return
      end
      cache[root] = parse(root, r.stdout or "")
      for _, b in ipairs(bufs) do
        decorate(b, root)
      end
    end)
  end)
end

local group = vim.api.nvim_create_augroup("sinbin_files_git", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "MiniFilesBufferUpdate",
  desc = "mini.files: Git status",
  callback = function(args)
    local buf = args.data.buf_id
    local ok, entry = pcall(MiniFiles.get_fs_entry, buf, 1)
    -- Shown directory = parent of its first entry. Empty folders have nothing to mark.
    if ok and entry then
      M.update(buf, vim.fs.dirname(vim.fs.normalize(entry.path)))
    end
  end,
})
-- Fresh status every time the explorer opens (files may have changed meanwhile).
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "MiniFilesExplorerOpen",
  desc = "mini.files: refresh Git status",
  callback = function() cache = {} end,
})
-- Colorschemes clear highlight groups.
vim.api.nvim_create_autocmd("ColorScheme", { group = group, desc = "mini.files Git colors", callback = set_hl })

return M
