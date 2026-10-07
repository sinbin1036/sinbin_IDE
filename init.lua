-- sinbin_IDE entry point.
-- Module layout: docs/ARCHITECTURE.md (Current).

-- Startup time shown on the start screen (sinbin/starter.lua).
vim.g.sinbin_start = vim.uv.hrtime()

-- Leader must be set before any mapping or plugin is defined.
require("sinbin.keymaps")
-- User settings (TASK-019) before anything that reads them.
require("sinbin.settings")
require("sinbin.options")
require("sinbin.autocmds")
require("sinbin.commands")
require("sinbin.diagnostics")
require("sinbin.platform").setup()
require("sinbin.plugins")
require("sinbin.terminal")
require("sinbin.run")
require("sinbin.lazygit")
require("sinbin.agent")
require("sinbin.ime")
