-- lazygit in a floating terminal (TASK-011). lazygit is an external CLI.
-- Terminal UX in general is Phase 7.

local M = {}

function M.open()
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("lazygit not found on PATH (see docs/USAGE.md)", vim.log.levels.WARN)
    return
  end

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })

  vim.fn.jobstart({ "lazygit" }, {
    term = true,
    -- Repository of the current file, else the working directory.
    cwd = vim.fs.root(0, ".git") or vim.fn.getcwd(),
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
        -- Commits, checkouts and resets may have changed open files.
        vim.cmd.checktime()
      end)
    end,
  })
  vim.cmd.startinsert()
end

vim.keymap.set("n", "<Leader>gg", M.open, { desc = "lazygit" })

return M
