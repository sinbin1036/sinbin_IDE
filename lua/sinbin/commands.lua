-- User commands.

-- Trailing whitespace is removed on demand only, never on save,
-- so editing other people's files does not produce unrelated diffs.
vim.api.nvim_create_user_command("TrimWhitespace", function(opts)
  local view = vim.fn.winsaveview()
  vim.cmd(string.format([[keeppatterns %d,%ds/\s\+$//e]], opts.line1, opts.line2))
  vim.fn.winrestview(view)
end, { range = "%", desc = "Remove trailing whitespace (whole buffer or range)" })

-- Settings panel (TASK-019).
vim.api.nvim_create_user_command("Settings", function() require("sinbin.settings_ui").open() end, { desc = "Settings panel" })

-- Back to the start screen (TASK-022); ! drops unsaved changes.
vim.api.nvim_create_user_command("Home", function(opts) require("sinbin.starter").home(opts.bang) end, {
  bang = true,
  desc = "Start screen, closing every file (! discards unsaved changes)",
})

-- Install / check (TASK-021); `:Setup update` also updates plugins, parsers and Mason
-- packages (TASK-023). Defined before the plugins load, so it exists without them.
vim.api.nvim_create_user_command("Setup", function(opts)
  if opts.args ~= "" and opts.args ~= "update" then
    vim.notify(":Setup 또는 :Setup update", vim.log.levels.WARN)
    return
  end
  require("sinbin.setup").run(opts.args == "update")
end, { nargs = "?", complete = function() return { "update" } end, desc = "Run the install script (setup.ps1), update: also update" })
