-- Plugin list, managed by the built-in vim.pack (docs/DECISIONS.md D-007).
-- Add each plugin with a one-line reason (docs/RULES.md Plugin).
-- Lock file: nvim-pack-lock.json at the repository root, tracked by git.

vim.pack.add({
  -- Auto-close brackets/quotes: no built-in equivalent.
  { src = "https://github.com/nvim-mini/mini.pairs", version = "stable" },
  -- Add/delete/replace surroundings: no built-in equivalent.
  { src = "https://github.com/nvim-mini/mini.surround", version = "stable" },
})

require("mini.pairs").setup()

-- tpope/vim-surround style keys (:h MiniSurround-vim-surround-config).
-- Keeps the built-in `s` key untouched.
require("mini.surround").setup({
  mappings = {
    add = "ys",
    delete = "ds",
    find = "",
    find_left = "",
    highlight = "",
    replace = "cs",
    suffix_last = "",
    suffix_next = "",
  },
  search_method = "cover_or_next",
})
vim.keymap.del("x", "ys")
vim.keymap.set("x", "S", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true, desc = "Add surrounding" })
vim.keymap.set("n", "yss", "ys_", { remap = true, desc = "Add surrounding to line" })
