-- Mixed Korean translation of diagnostic messages (TASK-010).
-- Display-only: callers pass the message, the diagnostic itself is never changed.

local rules = require("sinbin.diagnostics.rules_ko")

local M = {}

-- clangd appends this to messages that have a code action.
local FIX_SUFFIX = " (fix available)"

--- Translates the first line of a message.
--- @param message string
--- @return string? translated first line, or nil when no rule matches
function M.translate(message)
  local line = message:match("^[^\n]*")
  local suffix = ""
  if line:sub(-#FIX_SUFFIX) == FIX_SUFFIX then
    line = line:sub(1, -#FIX_SUFFIX - 1)
    suffix = " (fix 가능)"
  end
  for _, rule in ipairs(rules) do
    local out, n = line:gsub(rule[1], rule[2], 1)
    if n > 0 then
      return out .. suffix
    end
  end
end

return M
