-- Recent projects (TASK-018): every working directory change is saved to a list file,
-- most recent first. The start screen shows it.
local M = {}

local MAX = 10
local file = vim.fn.stdpath("data") .. "/sinbin/projects.txt"

local function normalize(dir) return vim.fs.normalize(vim.fn.fnamemodify(dir, ":p")) end

local function read()
  local ok, lines = pcall(vim.fn.readfile, file)
  return ok and lines or {}
end

--- Directories, most recent first. Missing ones are skipped.
--- @return string[]
function M.list()
  return vim.tbl_filter(function(dir) return vim.fn.isdirectory(dir) == 1 end, read())
end

--- Moves `dir` to the top of the list. The home directory is not a project.
--- @param dir string
function M.add(dir)
  dir = normalize(dir)
  if dir == normalize(vim.uv.os_homedir()) or vim.fn.isdirectory(dir) == 0 then
    return
  end
  local list = { dir }
  for _, d in ipairs(read()) do
    if d ~= dir and #list < MAX then
      list[#list + 1] = d
    end
  end
  vim.fn.mkdir(vim.fs.dirname(file), "p")
  pcall(vim.fn.writefile, list, file)
end

local group = vim.api.nvim_create_augroup("sinbin_projects", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  desc = "Record the startup working directory",
  callback = function()
    -- Headless runs (scripts, checks) are not project visits.
    if #vim.api.nvim_list_uis() == 0 then
      return
    end
    -- Plain `nvim` starts in the home directory (start screen, TASK-022); `nvim .` or
    -- `nvim <file>` keeps the directory it was started in as a project.
    if vim.fn.argc() == 0 then
      vim.fn.chdir(vim.uv.os_homedir())
      return
    end
    M.add(vim.fn.getcwd())
  end,
})
vim.api.nvim_create_autocmd("DirChanged", {
  group = group,
  pattern = "global",
  desc = "Record the new working directory",
  callback = function() M.add(vim.v.event.cwd) end,
})

return M
