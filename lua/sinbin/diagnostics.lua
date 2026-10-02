-- Diagnostics (TASK-009): built-in vim.diagnostic display and keymaps.
-- Picker keymaps that need mini.extra live in plugins/search.lua.

local severity = vim.diagnostic.severity

vim.diagnostic.config({
  severity_sort = true,
  -- Message at the end of every line with a diagnostic (user choice).
  virtual_text = { prefix = "●", spacing = 2 },
  -- Nerd Font icons instead of the default E/W/I/H letters.
  signs = {
    text = {
      [severity.ERROR] = "",
      [severity.WARN] = "",
      [severity.INFO] = "",
      [severity.HINT] = "",
    },
  },
  float = { border = "rounded", source = "if_many" },
  -- ]d / [d also open the full message, since virtual_text can be cut off.
  jump = {
    on_jump = function(diagnostic, bufnr)
      if diagnostic then
        -- Deferred: opened right away, the float is closed by the jump's own CursorMoved.
        vim.schedule(function()
          vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
        end)
      end
    end,
  },
})

local map = vim.keymap.set

map("n", "<Leader>ee", vim.diagnostic.open_float, { desc = "Diagnostic under cursor" })
map("n", "<Leader>eq", vim.diagnostic.setqflist, { desc = "Diagnostics to quickfix" })
map("n", "<Leader>et", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
