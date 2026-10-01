-- Editor options. OS-neutral only; OS-specific values belong in sinbin.platform.

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"

-- Indent (filetype plugins may override per language)
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Clipboard: share the system clipboard. The provider itself is platform-dependent.
opt.clipboard = "unnamedplus"

-- Persistent undo (stored under stdpath("state"))
opt.undofile = true

-- Windows / scrolling
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8

-- Visual aids
opt.cursorline = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Long lines: soft-wrap at word boundaries, keeping the indent
opt.wrap = true
opt.linebreak = true
opt.breakindent = true

-- Live preview of :substitute in a split
opt.inccommand = "split"
