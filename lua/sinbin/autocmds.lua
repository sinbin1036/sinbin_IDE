-- Global autocommands. All belong to one augroup so re-sourcing does not duplicate them.

local group = vim.api.nvim_create_augroup("sinbin", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Commit/rebase messages always start at the top.
local no_restore = { gitcommit = true, gitrebase = true }

vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  desc = "Restore last cursor position",
  callback = function(args)
    -- This runs before filetype detection, so 'filetype' is still empty here.
    if no_restore[vim.filetype.match({ buf = args.buf }) or ""] then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Reload files changed outside Neovim (AI Agent, git, formatters). 'autoread' is on by default.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose", "TermLeave" }, {
  group = group,
  desc = "Check for files changed outside Neovim",
  callback = function()
    if vim.fn.getcmdwintype() == "" and vim.fn.mode() ~= "c" then
      vim.cmd.checktime()
    end
  end,
})

-- Auto save (settings panel, TASK-019, off by default): leaving Insert mode, the buffer
-- or Neovim writes a changed file. Only named, writable, ordinary files.
vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave", "FocusLost" }, {
  group = group,
  desc = "Auto save",
  callback = function(args)
    local bo = vim.bo[args.buf]
    if
      not require("sinbin.settings").get("autosave")
      or bo.buftype ~= ""
      or not bo.modified
      or bo.readonly
      or not bo.modifiable
      or vim.api.nvim_buf_get_name(args.buf) == ""
    then
      return
    end
    vim.api.nvim_buf_call(args.buf, function() vim.cmd("silent! update") end)
  end,
})
