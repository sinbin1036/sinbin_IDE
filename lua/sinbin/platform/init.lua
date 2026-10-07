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
M.is_ssh = vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil

-- Over SSH the remote host has no access to the local clipboard: copy through the
-- terminal with OSC 52. Windows Terminal does not answer OSC 52 reads, so paste
-- returns the last copy made in this Neovim instead of waiting on the terminal.
local function ssh_clipboard()
  local osc52 = require("vim.ui.clipboard.osc52")
  local last = { {}, "v" }
  local function copy(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      last = { lines, regtype }
      send(lines)
    end
  end
  local function paste()
    return last
  end
  vim.g.clipboard = {
    name = "OSC 52 (copy only)",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

function M.setup()
  require("sinbin.platform." .. M.os).setup(M)
  if M.is_ssh then
    ssh_clipboard()
  end
end

return M
