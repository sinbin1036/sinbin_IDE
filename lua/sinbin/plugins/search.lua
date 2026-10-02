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
  -- Toggle. Checks the state instead of close()'s result: close() returns false when
  -- the user keeps unsynced edits, which must not reopen the explorer.
  if MiniFiles.get_explorer_state() then
    MiniFiles.close()
    return
  end
  -- Open at the current file; fall back to cwd for unnamed/unsaved buffers.
  local path = vim.api.nvim_buf_get_name(0)
  MiniFiles.open(vim.uv.fs_stat(path) and path or nil)
end, { desc = "File explorer (toggle)" })

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

-- Terminal list (TASK-012): pick a live shell terminal to show.
map("n", "<Leader>tl", function()
  local terminal = require("sinbin.terminal")
  local items = {}
  for _, t in ipairs(terminal.list()) do
    items[#items + 1] = { text = t.name, bufnr = t.buf, id = t.id }
  end
  if #items == 0 then
    vim.notify("열린 terminal 없음", vim.log.levels.INFO)
    return
  end
  pick.start({
    source = {
      name = "Terminals",
      items = items,
      choose = function(item)
        -- Leave the picker window before opening a split.
        vim.schedule(function() terminal.show(item.id) end)
      end,
    },
  })
end, { desc = "Terminal list" })
