-- Windows side of sinbin.ime (TASK-017): runs ime_helper.cs, compiled once into
-- stdpath("data")/sinbin/ime-helper.exe with the .NET Framework csc.exe (ships with
-- Windows). Rebuilt when the source is newer than the exe.

local M = {}

-- Found on 'runtimepath' (debug.getinfo has no directory when loaded through vim.loader).
local source = vim.api.nvim_get_runtime_file("lua/sinbin/platform/ime_helper.cs", false)[1]
local exe = vim.fs.joinpath(vim.fn.stdpath("data"), "sinbin", "ime-helper.exe")

-- Terminals Neovim may run in: the helper only acts when one of them is the
-- foreground window.
local TERMINALS = { "WindowsTerminal", "OpenConsole", "conhost", "wezterm-gui", "alacritty" }

local building = false
local failed = false

local function csc()
  local windir = vim.env.WINDIR or "C:\\Windows"
  for _, dir in ipairs({ "Framework64", "Framework" }) do
    local path = vim.fs.joinpath(windir, "Microsoft.NET", dir, "v4.0.30319", "csc.exe")
    if vim.uv.fs_stat(path) then
      return path
    end
  end
end

local function up_to_date()
  local s, e = source and vim.uv.fs_stat(source), vim.uv.fs_stat(exe)
  return s and e and e.mtime.sec >= s.mtime.sec
end

--- Builds the helper, then calls `cb` (only when the build succeeded).
local function build(cb)
  if building or failed then
    return
  end
  local compiler = csc()
  if not compiler or not source then
    failed = true
    vim.notify("한/영 자동 전환: csc.exe(.NET Framework) 없음", vim.log.levels.WARN)
    return
  end
  building = true
  vim.fn.mkdir(vim.fs.dirname(exe), "p")
  vim.system({ compiler, "/nologo", "/optimize", "/target:exe", "/out:" .. exe, source }, { text = true }, function(r)
    vim.schedule(function()
      building = false
      if r.code ~= 0 then
        failed = true
        vim.notify("한/영 자동 전환: 도우미 빌드 실패\n" .. (r.stdout or "") .. (r.stderr or ""), vim.log.levels.WARN)
        return
      end
      cb()
    end)
  end)
end

local function run(mode, on_result)
  local cmd = { exe, mode }
  vim.list_extend(cmd, TERMINALS)
  vim.system(cmd, { text = true }, on_result and function(r)
    vim.schedule(function() on_result(r) end)
  end or nil)
end

--- Korean IME state -> English, nothing when already English. Asynchronous.
function M.to_english()
  if up_to_date() then
    run("to-english")
  else
    build(function() run("to-english") end)
  end
end

--- Current state for checking: calls `cb("ko" | "en" | nil)`.
function M.state(cb)
  local function get()
    run("get", function(r) cb(r.code == 0 and r.stdout or nil) end)
  end
  if up_to_date() then
    get()
  else
    build(get)
  end
end

return M
