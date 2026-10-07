-- Platform settings for windows.

local M = {}

-- Git Bash, found next to git.exe. A plain exepath("bash") can resolve to the
-- WSL launcher in WindowsApps instead.
local function git_bash()
  local git = vim.fn.exepath("git")
  if git == "" then
    return nil
  end
  -- git.exe sits in <Git>\cmd, <Git>\bin or <Git>\mingw64\bin (inside Git Bash).
  for dir in vim.fs.parents(git) do
    local bash = vim.fs.joinpath(dir, "bin", "bash.exe")
    if vim.uv.fs_stat(bash) then
      return bash
    end
  end
end

function M.setup(platform)
  -- Started from Git Bash, Neovim takes 'shell' from $SHELL (bash.exe) but keeps the
  -- cmd.exe 'shellcmdflag' etc., so :! and system() break ("/s: No such file").
  -- Use cmd.exe as when started from PowerShell; terminal windows use Git Bash below.
  if not vim.o.shell:lower():find("cmd") then
    vim.o.shell = vim.env.COMSPEC or "cmd.exe"
  end

  -- The Flutter SDK ships an extensionless `dart` shell script next to `dart.bat`.
  -- exepath() picks the script, which cannot be spawned on Windows (ENOENT).
  vim.lsp.config("dartls", { cmd = { "dart.bat", "language-server", "--protocol=lsp" } })

  -- Shell for terminal windows (TASK-012). 'shell' itself is left alone so :! and
  -- system() keep their default quoting. Falls back to 'shell' when Git Bash is missing.
  local bash = git_bash()
  if bash then
    platform.terminal_shell = { bash, "--login", "-i" }
    -- Run/Test commands (TASK-013) go through bash too: npm, mvn and flutter ship
    -- extensionless shell scripts next to their .cmd/.bat that cannot be spawned directly.
    platform.terminal_exec = function(cmd)
      return { bash, "-c", cmd }
    end
  end

  -- Install script for :Setup (TASK-021), run from the repository root. `update`:
  -- :Setup update also updates plugins, parsers and Mason packages (TASK-023).
  platform.setup_cmd = function(root, update)
    local cmd = { "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", vim.fs.joinpath(root, "setup.ps1") }
    if update then
      table.insert(cmd, "-Update")
    end
    return cmd
  end

  -- Python launcher name (Linux/macOS usually only have python3).
  platform.python = "python"

  -- Korean IME Han/Eng state for sinbin.ime (TASK-017).
  platform.ime = require("sinbin.platform.windows_ime")

  -- Suffix of compiled executables (Debug, TASK-014).
  platform.exe_suffix = ".exe"
  -- Python venv executables directory (Linux/macOS: bin).
  platform.venv_bin = "Scripts"

  -- Real dart.exe of the Flutter SDK for debug adapters: dart.bat goes through cmd.exe,
  -- which the debug protocol over stdio does not get through.
  local dart_bat = vim.fn.exepath("dart.bat")
  if dart_bat ~= "" then
    local exe = vim.fs.joinpath(vim.fs.dirname(dart_bat), "cache", "dart-sdk", "bin", "dart.exe")
    if vim.uv.fs_stat(exe) then
      platform.dart_exe = exe
      -- What flutter.bat runs: `flutter <args>` = dart.exe --packages=... flutter_tools.snapshot <args>
      local root = vim.fs.dirname(vim.fs.dirname(dart_bat))
      local snapshot = vim.fs.joinpath(root, "bin", "cache", "flutter_tools.snapshot")
      local packages = vim.fs.joinpath(root, "packages", "flutter_tools", ".dart_tool", "package_config.json")
      if vim.uv.fs_stat(snapshot) and vim.uv.fs_stat(packages) then
        platform.flutter_cmd = { exe, "--packages=" .. packages, snapshot }
      end
    end
  end
end

return M
