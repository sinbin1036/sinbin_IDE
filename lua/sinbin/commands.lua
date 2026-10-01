-- User commands.

-- Trailing whitespace is removed on demand only, never on save,
-- so editing other people's files does not produce unrelated diffs.
vim.api.nvim_create_user_command("TrimWhitespace", function(opts)
  local view = vim.fn.winsaveview()
  vim.cmd(string.format([[keeppatterns %d,%ds/\s\+$//e]], opts.line1, opts.line2))
  vim.fn.winrestview(view)
end, { range = "%", desc = "Remove trailing whitespace (whole buffer or range)" })
