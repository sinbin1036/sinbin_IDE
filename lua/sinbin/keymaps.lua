-- Leader key and global keymaps.
-- Feature keymaps are added per Phase, following the Leader groups
-- in docs/PROJECT.md "Keymap 방향".

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- <Space> must not move the cursor while waiting for a leader sequence.
vim.keymap.set({ "n", "x" }, "<Space>", "<Nop>", { silent = true })

-- Editing (Phase 2). Overrides built-in Visual J (join) and K (keywordprg),
-- see docs/tasks TASK-005.
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR><Esc>", { desc = "Clear search highlight" })
vim.keymap.set("x", "J", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("x", "K", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })
vim.keymap.set("x", "<", "<gv", { desc = "Indent left, keep selection" })
vim.keymap.set("x", ">", ">gv", { desc = "Indent right, keep selection" })

-- Settings panel (TASK-019), also :Settings and `c` on the start screen.
vim.keymap.set("n", "<Leader>,", function() require("sinbin.settings_ui").open() end, { desc = "Settings" })

-- Window moves (TASK-016): Alt+h/j/k/l, also straight out of a terminal, so programs
-- in it keep Ctrl+h/j/k/l. Windows Terminal binds only Alt+arrows (pane focus).
for key, dir in pairs({ h = "h", j = "j", k = "k", l = "l" }) do
  vim.keymap.set({ "n", "t" }, "<M-" .. key .. ">", "<Cmd>wincmd " .. dir .. "<CR>", { desc = "Window " .. dir })
end
