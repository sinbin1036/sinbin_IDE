-- Search / Navigation plugins (TASK-006): mini.pick, mini.extra, mini.files.
-- Keymaps follow the <Leader>f File / <Leader>s Search groups (docs/PROJECT.md).
-- Content search uses ripgrep (rg) when present.

local pick = require("mini.pick")
pick.setup()
require("mini.extra").setup()
require("mini.files").setup()

local map = vim.keymap.set

map("n", "<Leader>ff", pick.builtin.files, { desc = "Find files" })
map("n", "<Leader>fb", pick.builtin.buffers, { desc = "Buffers" })
map("n", "<Leader>fr", function() MiniExtra.pickers.oldfiles() end, { desc = "Recent files" })
map("n", "<Leader>fe", function()
  -- Open at the current file; fall back to cwd for unnamed/unsaved buffers.
  local path = vim.api.nvim_buf_get_name(0)
  MiniFiles.open(vim.uv.fs_stat(path) and path or nil)
end, { desc = "File explorer" })

map("n", "<Leader>sg", pick.builtin.grep_live, { desc = "Grep (live)" })
map("n", "<Leader>sw", function()
  pick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Grep word under cursor" })
map("n", "<Leader>sh", pick.builtin.help, { desc = "Help tags" })
map("n", "<Leader>sr", pick.builtin.resume, { desc = "Resume last picker" })

-- Diagnostic pickers (TASK-009). Other <Leader>e keymaps are in sinbin/diagnostics.lua.
map("n", "<Leader>ed", function()
  MiniExtra.pickers.diagnostic({ scope = "current" })
end, { desc = "Diagnostics (buffer)" })
map("n", "<Leader>eD", function()
  MiniExtra.pickers.diagnostic({ scope = "all" })
end, { desc = "Diagnostics (all)" })
