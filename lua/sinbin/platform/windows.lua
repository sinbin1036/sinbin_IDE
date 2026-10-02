-- Platform settings for windows. General setup is implemented in Phase 12 (Cross-platform Setup).

local M = {}

function M.setup(_platform)
  -- The Flutter SDK ships an extensionless `dart` shell script next to `dart.bat`.
  -- exepath() picks the script, which cannot be spawned on Windows (ENOENT).
  vim.lsp.config("dartls", { cmd = { "dart.bat", "language-server", "--protocol=lsp" } })
end

return M
