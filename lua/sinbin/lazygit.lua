-- lazygit in a floating terminal (TASK-011). lazygit is an external CLI.

local M = {}

function M.open()
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("lazygit not found on PATH (see docs/USAGE.md)", vim.log.levels.WARN)
    return
  end
  require("sinbin.terminal").run_float({ "lazygit" }, {
    -- Repository of the current file, else the working directory.
    cwd = vim.fs.root(0, ".git") or vim.fn.getcwd(),
    -- Commits, checkouts and resets may have changed open files.
    on_exit = function() vim.cmd.checktime() end,
  })
end

vim.keymap.set("n", "<Leader>gg", M.open, { desc = "lazygit" })

return M
