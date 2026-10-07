-- sinbin_IDE entry point.
-- Module layout: docs/ARCHITECTURE.md (Current).

-- Leader must be set before any mapping or plugin is defined.
require("sinbin.keymaps")
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
