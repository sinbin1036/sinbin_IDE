-- Debug (TASK-014): nvim-dap client, nvim-dap-view panel, per-language adapters.
-- .vscode/launch.json is read by nvim-dap itself when a session starts.
-- Loaded on the first debug key by plugins/debug.lua (TASK-023), after packadd.

local dap = require("dap")
local platform = require("sinbin.platform")

require("dap-view").setup({
  winbar = {
    -- Console merges the program output into the panel.
    sections = { "scopes", "watches", "breakpoints", "threads", "exceptions", "repl", "console" },
    default_section = "scopes",
  },
  -- Bottom, same height as the bottom panel; right of the panel when it is open (TASK-016).
  windows = {
    size = function() return require("sinbin.layout").bottom_height() end,
    anchor = function() return require("sinbin.layout").panel_win() end,
    -- Next to the panel dap-view takes 'columns' - terminal.size columns: half the panel.
    terminal = {
      size = function()
        local panel = require("sinbin.layout").panel_win()
        return panel and vim.o.columns - math.floor(vim.api.nvim_win_get_width(panel) / 2) or 0.5
      end,
    },
  },
  -- Open with a session, close when it ends.
  auto_toggle = true,
  -- Values at the end of lines while stopped, like `x = 3`.
  virtual_text = { enabled = true, position = "eol" },
})

-- Gutter icons (Nerd Font).
for name, icon in pairs({
  DapBreakpoint = { "", "DiagnosticError" },
  DapBreakpointCondition = { "", "DiagnosticWarn" },
  DapBreakpointRejected = { "", "DiagnosticHint" },
  DapLogPoint = { "", "DiagnosticInfo" },
  DapStopped = { "", "DiagnosticOk" },
}) do
  vim.fn.sign_define(name, { text = icon[1], texthl = icon[2], numhl = "", linehl = name == "DapStopped" and "Visual" or "" })
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.WARN)
end

--- Full path of an adapter executable. nvim-dap spawns adapters with libuv, which does
--- not resolve Windows .cmd shims (Mason installs debugpy-adapter.cmd etc.) by name.
local function exe(name)
  local path = vim.fn.exepath(name)
  return path ~= "" and path or name
end

--- Adapter executable check, so a missing adapter gives a reason instead of a stack trace.
local function require_exe(path, hint)
  if vim.fn.executable(path) == 1 or vim.uv.fs_stat(path) then
    return true
  end
  notify(("%s 없음 (%s)"):format(vim.fn.fnamemodify(path, ":t"), hint))
  return false
end

------------------------------------------------------------------------------
-- C: gdb's built-in DAP mode (gdb 14+). The current file is compiled with -g first.
dap.adapters.gdb = function(cb)
  cb({ type = "executable", command = exe("gdb"), args = { "--interpreter=dap", "--eval-command", "set print pretty on" } })
end

--- Compiles the current C file for debugging and returns the executable path.
local function compile_current_c()
  local file = vim.api.nvim_buf_get_name(0)
  local out = vim.fn.fnamemodify(file, ":r") .. (platform.exe_suffix or "")
  local r = vim.system({ "gcc", "-g", "-O0", file, "-o", out }, { text = true }):wait()
  if r.code ~= 0 then
    notify("gcc 컴파일 실패:\n" .. (r.stderr or ""), vim.log.levels.ERROR)
    return dap.ABORT
  end
  return out
end

dap.configurations.c = {
  {
    name = "현재 파일 디버그 (gcc -g 컴파일 후 gdb)",
    type = "gdb",
    request = "launch",
    program = compile_current_c,
    cwd = "${fileDirname}",
  },
  {
    name = "실행 파일 지정 (gdb)",
    type = "gdb",
    request = "launch",
    program = function()
      return vim.fn.input("실행 파일: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
  },
}

------------------------------------------------------------------------------
-- Python: debugpy (Mason). The debuggee runs with the same Python as Run (platform.python).
--- Path inside a Mason package ($MASON is set by mason.setup()).
local function mason_path(...)
  return vim.fs.joinpath(vim.env.MASON or (vim.fn.stdpath("data") .. "/mason"), "packages", ...)
end

-- The real entry points, not Mason's .cmd shims: the debug protocol over stdio does not
-- get through the nested cmd.exe shims on Windows (no response to `initialize`).
-- Functions resolve paths at session start (the adapter may be installed later).
local function debugpy_python()
  local bin = platform.venv_bin or "bin"
  return mason_path("debugpy", "venv", bin, "python" .. (platform.exe_suffix or ""))
end

dap.adapters.python = function(cb)
  cb({ type = "executable", command = debugpy_python(), args = { "-m", "debugpy.adapter" } })
end

local function python_path()
  return vim.fn.exepath(platform.python or "python3")
end

dap.configurations.python = {
  {
    name = "현재 파일 디버그 (python)",
    type = "python",
    request = "launch",
    program = "${file}",
    cwd = "${fileDirname}",
    pythonPath = python_path,
    -- Program input()/output in the debug panel's console.
    console = "integratedTerminal",
  },
  {
    name = "pytest: 현재 파일",
    type = "python",
    request = "launch",
    module = "pytest",
    args = { "${file}" },
    cwd = "${workspaceFolder}",
    pythonPath = python_path,
    console = "integratedTerminal",
  },
}

------------------------------------------------------------------------------
-- JavaScript / TypeScript (Node): vscode-js-debug via js-debug-adapter (Mason).
dap.adapters["pwa-node"] = function(cb)
  cb({
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = exe("node"),
      args = { mason_path("js-debug-adapter", "js-debug", "src", "dapDebugServer.js"), "${port}" },
    },
  })
end

local node_configs = function(runtime_args)
  return {
    {
      name = "현재 파일 디버그 (node)",
      type = "pwa-node",
      request = "launch",
      program = "${file}",
      cwd = "${workspaceFolder}",
      runtimeArgs = runtime_args,
      console = "integratedTerminal",
    },
    {
      name = "실행 중인 node 프로세스에 attach",
      type = "pwa-node",
      request = "attach",
      processId = function() return require("dap.utils").pick_process({ filter = "node" }) end,
      cwd = "${workspaceFolder}",
    },
  }
end

dap.configurations.javascript = node_configs(nil)
-- Same Node 22 flags as Run (<Leader>rr) so enums etc. work.
dap.configurations.typescript = node_configs({ "--experimental-transform-types", "--no-warnings" })

------------------------------------------------------------------------------
-- Dart: the SDK's own debug adapter (`dart debug_adapter`).
local function dart_exe()
  return platform.dart_exe or exe("dart")
end

dap.adapters.dart = function(cb)
  cb({ type = "executable", command = dart_exe(), args = { "debug_adapter" } })
end

-- Flutter: `flutter debug_adapter`. On Windows the Platform Layer gives the command
-- flutter.bat runs, without cmd.exe in between.
dap.adapters.flutter = function(cb)
  local cmd = platform.flutter_cmd and vim.deepcopy(platform.flutter_cmd) or { exe("flutter") }
  local command = table.remove(cmd, 1)
  table.insert(cmd, "debug_adapter")
  cb({ type = "executable", command = command, args = cmd })
end

--- Flutter app entry: the current file if it is under lib/, else lib/main.dart.
local function flutter_program()
  local file = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.root(file, "pubspec.yaml") or vim.fn.getcwd()
  if file:gsub("\\", "/"):find("/lib/") then
    return file
  end
  return vim.fs.joinpath(root, "lib", "main.dart")
end

local function flutter_root()
  return vim.fs.root(vim.api.nvim_buf_get_name(0), "pubspec.yaml") or vim.fn.getcwd()
end

local function flutter_config(device, label)
  return {
    name = ("Flutter 앱 디버그 (%s)"):format(label),
    type = "flutter",
    request = "launch",
    program = flutter_program,
    cwd = flutter_root,
    toolArgs = { "-d", device },
  }
end

dap.configurations.dart = {
  {
    name = "현재 파일 디버그 (dart)",
    type = "dart",
    request = "launch",
    program = "${file}",
    cwd = "${workspaceFolder}",
  },
  flutter_config("windows", "Windows"),
  flutter_config("chrome", "Chrome"),
}

------------------------------------------------------------------------------
-- Java: java-debug (Mason) runs inside jdtls as a bundle. jdtls starts the debug
-- server and resolves main class / classpath through workspace commands.
local java_bundles = vim.fn.glob(mason_path("java-debug-adapter", "extension", "server", "com.microsoft.java.debug.plugin-*.jar"), true, true)
if #java_bundles > 0 then
  -- Merged into the nvim-lspconfig jdtls config; applies to jdtls clients started later.
  vim.lsp.config("jdtls", { init_options = { bundles = java_bundles } })
end

local function jdtls_client()
  return vim.lsp.get_clients({ name = "jdtls", bufnr = 0 })[1]
end

--- Runs a jdtls workspace command synchronously (inside the dap coroutine is fine too).
local function jdtls_command(command, arguments)
  local client = jdtls_client()
  if not client then
    error("jdtls가 연결되지 않음 (Java 파일을 열고 LSP 연결 후 다시)")
  end
  local resp = client:request_sync("workspace/executeCommand", { command = command, arguments = arguments }, 60000, 0)
  if not resp or resp.err then
    error(("%s 실패: %s"):format(command, resp and vim.inspect(resp.err) or "timeout"))
  end
  return resp.result
end

dap.adapters.java = function(cb)
  local port = jdtls_command("vscode.java.startDebugSession")
  cb({ type = "server", host = "127.0.0.1", port = port })
end

--- Main class entry of the current file (fqcn + project) from jdtls.
local function java_main()
  local file = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  for _, m in ipairs(jdtls_command("vscode.java.resolveMainClass") or {}) do
    if vim.fs.normalize(m.filePath or "") == file then
      return m
    end
  end
  error("이 파일에 main 메서드 없음")
end

dap.configurations.java = {
  {
    name = "현재 클래스 디버그 (main)",
    type = "java",
    request = "launch",
    -- Fields resolved when the session starts.
    mainClass = function() return java_main().mainClass end,
    projectName = function() return java_main().projectName end,
    classPaths = function()
      local m = java_main()
      return jdtls_command("vscode.java.resolveClasspath", { m.mainClass, m.projectName })[2]
    end,
    modulePaths = function()
      local m = java_main()
      return jdtls_command("vscode.java.resolveClasspath", { m.mainClass, m.projectName })[1]
    end,
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
  },
}

------------------------------------------------------------------------------
local M = {}

--- <Leader>dc / F5: a missing debug config or adapter gives a reason first.
function M.start_or_continue()
  local ft = vim.bo.filetype
  if not dap.session() and dap.configurations[ft] == nil and not vim.uv.fs_stat(vim.fn.getcwd() .. "/.vscode/launch.json") then
    notify(("%s 디버그 설정 없음"):format(ft ~= "" and ft or "이 파일"))
    return
  end
  if not dap.session() then
    local need = ({
      c = { "gdb", "MSYS2 gdb 설치 필요" },
      python = { debugpy_python(), ":MasonInstall debugpy" },
      javascript = { mason_path("js-debug-adapter", "js-debug", "src", "dapDebugServer.js"), ":MasonInstall js-debug-adapter" },
      typescript = { mason_path("js-debug-adapter", "js-debug", "src", "dapDebugServer.js"), ":MasonInstall js-debug-adapter" },
      dart = { dart_exe(), "Dart/Flutter SDK 필요" },
      java = { java_bundles[1] or "java-debug-adapter", ":MasonInstall java-debug-adapter 후 nvim 재시작" },
    })[ft]
    if need and not require_exe(need[1], need[2]) then
      return
    end
  end
  dap.continue()
end

return M
