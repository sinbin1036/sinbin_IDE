-- Platform settings for windows. General setup is implemented in Phase 12 (Cross-platform Setup).

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

  -- Python launcher name (Linux/macOS usually only have python3).
  platform.python = "python"
end

return M
