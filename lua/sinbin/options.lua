-- Editor options. OS-neutral only; OS-specific values belong in sinbin.platform.
-- Values the settings panel can change come from sinbin.settings (TASK-019).

local opt = vim.opt
local settings = require("sinbin.settings")

-- Line numbers
opt.number = true
opt.relativenumber = settings.get("relativenumber")
opt.signcolumn = "yes"

-- Indent (filetype plugins may override per language)
opt.expandtab = settings.get("expandtab")
opt.shiftwidth = settings.get("indent")
opt.tabstop = settings.get("indent")
opt.softtabstop = settings.get("indent")
opt.smartindent = true

-- Search
opt.ignorecase = settings.get("search_case") ~= "match"
opt.smartcase = settings.get("search_case") == "smart"

-- Remote plugin providers: no plugin here uses them (all Lua). Off, so startup does not
-- probe for python / node / ruby / perl hosts and :checkhealth does not warn (TASK-023).
for _, lang in ipairs({ "python3", "node", "ruby", "perl" }) do
  vim.g["loaded_" .. lang .. "_provider"] = 0
end

-- Clipboard: share the system clipboard. The provider itself is platform-dependent.
opt.clipboard = "unnamedplus"

-- Persistent undo (stored under stdpath("state"))
opt.undofile = true

-- Windows / scrolling
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = settings.get("scrolloff")

-- Visual aids
opt.cursorline = settings.get("cursorline")
opt.list = settings.get("list")
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Long lines: soft-wrap at word boundaries, keeping the indent
opt.wrap = settings.get("wrap")
opt.linebreak = true
opt.breakindent = true

-- Live preview of :substitute in a split
opt.inccommand = "split"

-- One statusline for the whole screen, like VS Code (TASK-016)
opt.laststatus = 3
