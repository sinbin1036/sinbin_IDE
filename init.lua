-- sinbin_IDE entry point.
-- Module layout: docs/ARCHITECTURE.md (Current).

-- Leader must be set before any mapping or plugin is defined.
require("sinbin.keymaps")
require("sinbin.options")
require("sinbin.platform").setup()
