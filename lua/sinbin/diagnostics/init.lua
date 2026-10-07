-- Diagnostics (TASK-009): built-in vim.diagnostic display and keymaps.
-- Picker keymaps that need mini.extra live in plugins/search.lua.
-- Messages are shown in mixed Korean (TASK-010); pickers and quickfix keep the original.

local severity = vim.diagnostic.severity
local translate = require("sinbin.diagnostics.translate").translate

vim.diagnostic.config({
  severity_sort = true,
  -- Message at the end of every line with a diagnostic (user choice). Translation only.
  virtual_text = {
    prefix = "●",
    spacing = 2,
    format = function(d) return translate(d.message) or d.message end,
  },
  -- Nerd Font icons instead of the default E/W/I/H letters.
  signs = {
    text = {
      [severity.ERROR] = "",
      [severity.WARN] = "",
      [severity.INFO] = "",
      [severity.HINT] = "",
    },
  },
  -- Translation on top, original message below (for searching).
  float = {
    border = "rounded",
    source = "if_many",
    format = function(d)
      local ko = translate(d.message)
      return ko and (ko .. "\n" .. d.message) or d.message
    end,
  },
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

-- Off from the settings panel (TASK-019). <Leader>et below toggles without saving.
if not require("sinbin.settings").get("diagnostics") then
  vim.diagnostic.enable(false)
end

local map = vim.keymap.set

map("n", "<Leader>ee", vim.diagnostic.open_float, { desc = "Diagnostic under cursor" })
map("n", "<Leader>et", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
