-- Leader key and global keymaps.
-- Feature keymaps are added per Phase, following the Leader groups
-- in docs/PROJECT.md "Keymap 방향".

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- <Space> must not move the cursor while waiting for a leader sequence.
vim.keymap.set({ "n", "x" }, "<Space>", "<Nop>", { silent = true })
