-- Platform Layer entry point (docs/DECISIONS.md D-003).
-- The only place allowed to branch on OS. Other modules read M.os / M.is_wsl
-- instead of calling vim.fn.has("win32") etc. themselves.

local M = {}

local function detect()
  local sysname = vim.uv.os_uname().sysname
  if sysname == "Windows_NT" then
    return "windows"
  elseif sysname == "Darwin" then
    return "macos"
  end
  return "linux"
end

M.os = detect()
M.is_wsl = M.os == "linux" and vim.fn.has("wsl") == 1

function M.setup()
  require("sinbin.platform." .. M.os).setup(M)
end

return M
