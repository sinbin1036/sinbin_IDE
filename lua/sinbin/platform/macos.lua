-- Platform settings for macos. The other modules default to Unix values when a
-- field is not set: terminal_shell/terminal_exec -> 'shell' ($SHELL),
-- venv_bin -> "bin", exe_suffix -> "", dart_exe/flutter_cmd -> dart/flutter on PATH,
-- ime -> none (no Han/Eng switching).

local M = {}

function M.setup(platform)
  -- Only python3 is installed by default on most distributions and macOS.
  platform.python = "python3"
end

return M
