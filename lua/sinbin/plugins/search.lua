-- Search / Navigation plugins (TASK-006): mini.pick, mini.extra.
-- Keymaps follow the <Leader>f File / <Leader>s Search groups (docs/PROJECT.md).
-- Content search uses ripgrep (rg) when present.

local pick = require("mini.pick")
-- No <C-t> "open in a new tabpage": tabpages are not part of the layout (TASK-016) and
-- were easy to create by accident. <C-v> / <C-s> splits stay.
pick.setup({ mappings = { choose_in_tabpage = "" } })
require("mini.extra").setup()

local map = vim.keymap.set

map("n", "<Leader>ff", pick.builtin.files, { desc = "Find files" })
-- VS Code Ctrl+P (TASK-016); replaces the built-in Normal <C-p> (= k).
map("n", "<C-p>", pick.builtin.files, { desc = "Find files" })
map("n", "<Leader>fb", pick.builtin.buffers, { desc = "Buffers" })
map("n", "<Leader>fr", function() MiniExtra.pickers.oldfiles() end, { desc = "Recent files" })
map("n", "<Leader>sg", pick.builtin.grep_live, { desc = "Grep (live)" })
map("n", "<Leader>sw", function()
  pick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Grep word under cursor" })
map("n", "<Leader>sh", pick.builtin.help, { desc = "Help tags" })
map("n", "<Leader>sr", pick.builtin.resume, { desc = "Resume last picker" })
-- Project-wide symbols: a search, separate from the current file's Outline (TASK-016).
map("n", "<Leader>ss", function()
  MiniExtra.pickers.lsp({ scope = "workspace_symbol_live" })
end, { desc = "Symbols (project)" })
-- Command palette (TASK-016): commands and keymaps.
map("n", "<Leader>sc", function() MiniExtra.pickers.commands() end, { desc = "Commands" })
map("n", "<Leader>sk", function() MiniExtra.pickers.keymaps() end, { desc = "Keymaps" })

-- Diagnostic pickers (TASK-009). Other <Leader>e keymaps are in sinbin/diagnostics.lua.
map("n", "<Leader>ed", function()
  MiniExtra.pickers.diagnostic({ scope = "current" })
end, { desc = "Diagnostics (buffer)" })
map("n", "<Leader>eD", function()
  MiniExtra.pickers.diagnostic({ scope = "all" })
end, { desc = "Diagnostics (all)" })

-- Run/Test command list (TASK-013): [파일] / [프로젝트] commands of the current context.
map("n", "<Leader>rt", function()
  local run = require("sinbin.run")
  run.commands(function(items)
    pick.start({
      source = {
        name = "Run commands",
        items = items,
        choose = function(item)
          vim.schedule(function() run.run_item(item) end)
        end,
      },
    })
  end)
end, { desc = "Run command list" })
